param(
  [Parameter(Mandatory = $true)]
  [string]$Token,                              # GitHub classic PAT

  [string]$Owner = 'parennialgolf',
  [string]$Repo  = 'dotnet',

  [ValidateSet('setup','portable')]
  [string]$AssetType = 'setup',

  [switch]$IncludePrerelease,

  [string]$InstallArgs = ''                    # e.g. '--silent'
)

# -------------------------
# Global settings
# -------------------------
$ErrorActionPreference = 'Stop'
$ProgressPreference    = 'SilentlyContinue'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

Write-Host "=== Bay Management Installer ==="
Write-Host "Owner:    $Owner"
Write-Host "Repo:     $Repo"
Write-Host "Type:     $AssetType"
Write-Host "Prerelease included: $IncludePrerelease"
Write-Host ""

# -------------------------
# 0) Already installed?
# -------------------------
$ExePath = Join-Path $env:LOCALAPPDATA `
  'PARennialGolf.BayManagement.UI.V2\current\PARennialGolf.BayManagement.UI.V2.exe'

if (Test-Path $ExePath) {
    Write-Host ">>> Bay Management already installed:"
    Write-Host ">>> $ExePath"
    Write-Host ">>> Skipping install."
    exit 0
}

# -------------------------
# GitHub API setup
# -------------------------
$RepoApi = "https://api.github.com/repos/$Owner/$Repo"

$Headers = @{
  Authorization = "token $Token"   # ✅ REQUIRED for classic PATs
  'User-Agent'  = 'pg-installer'
  Accept        = 'application/vnd.github+json'
}

# -------------------------
# Preflight: repo access
# -------------------------
Write-Host "[0] Verifying repository access..."
try {
    Invoke-RestMethod -Headers $Headers -Uri $RepoApi -Method Get | Out-Null
}
catch {
    throw @"
Cannot access repository $Owner/$Repo.

Causes:
- Token is not classic
- Token not SSO-authorized for the org
- Token missing 'repo' scope

Fix:
GitHub → Settings → Developer Settings → Tokens → Authorize SSO
"@
}

# -------------------------
# 1) Fetch releases
# -------------------------
Write-Host "[1] Fetching releases..."
$ReleasesUrl = "$RepoApi/releases?per_page=30"
Write-Host "    URL: $ReleasesUrl"

$Releases = Invoke-RestMethod -Headers $Headers -Uri $ReleasesUrl

$Releases = $Releases | Where-Object { -not $_.draft }
if (-not $IncludePrerelease) {
    $Releases = $Releases | Where-Object { -not $_.prerelease }
}

if (-not $Releases) {
    throw "No visible published releases found for this repository."
}

$Release = $Releases |
    Sort-Object @{
        Expression = {
            if ($_.published_at) { Get-Date $_.published_at }
            else { Get-Date $_.created_at }
        }
    } -Descending |
    Select-Object -First 1

Write-Host "    Selected release: $($Release.tag_name) — $($Release.name)"
Write-Host ""

# -------------------------
# 2) Choose asset
# -------------------------
Write-Host "[2] Selecting asset..."

$PreferredName =
    if ($AssetType -eq 'setup') {
        'PARennialGolf.BayManagement.UI.V2-win-Setup.exe'
    } else {
        'PARennialGolf.BayManagement.UI.V2-win-Portable.zip'
    }

$Asset =
    $Release.assets |
    Where-Object { $_.name -eq $PreferredName } |
    Select-Object -First 1

if (-not $Asset) {
    $Pattern =
        if ($AssetType -eq 'setup') { '*-win-Setup.exe' }
        else { '*-win-Portable.zip' }

    $Asset =
        $Release.assets |
        Where-Object { $_.name -like $Pattern } |
        Select-Object -First 1
}

if (-not $Asset) {
    $names = ($Release.assets | ForEach-Object { $_.name }) -join ', '
    throw "No suitable asset found. Available assets: $names"
}

Write-Host "    Asset chosen: $($Asset.name)"
Write-Host ""

# -------------------------
# 3) Resolve signed download URL
# -------------------------
Write-Host "[3] Resolving signed download URL..."

Add-Type -AssemblyName System.Net.Http

$Handler = New-Object System.Net.Http.HttpClientHandler
$Handler.AllowAutoRedirect = $false

$Client = New-Object System.Net.Http.HttpClient($Handler)
$Client.DefaultRequestHeaders.UserAgent.ParseAdd('pg-installer')
$Client.DefaultRequestHeaders.Authorization =
    New-Object System.Net.Http.Headers.AuthenticationHeaderValue('token', $Token)

$Client.DefaultRequestHeaders.Accept.Clear()
$Client.DefaultRequestHeaders.Accept.Add(
    [System.Net.Http.Headers.MediaTypeWithQualityHeaderValue]::new('application/octet-stream')
)

$AssetApiUrl = "$RepoApi/releases/assets/$($Asset.id)"
$Request  = New-Object System.Net.Http.HttpRequestMessage('GET', $AssetApiUrl)
$Response = $Client.SendAsync($Request).Result

if (-not $Response.Headers.Location) {
    throw "Failed to resolve asset redirect URL."
}

$DownloadUrl = $Response.Headers.Location.AbsoluteUri
Write-Host "    Download URL resolved."
Write-Host ""

# -------------------------
# 4) Download
# -------------------------
Write-Host "[4] Downloading asset..."
$OutFile = Join-Path $env:TEMP $Asset.name

Invoke-WebRequest `
  -Uri $DownloadUrl `
  -OutFile $OutFile `
  -MaximumRedirection 5 `
  -TimeoutSec 600

$Hash = (Get-FileHash -Algorithm SHA256 -Path $OutFile).Hash
Write-Host "    Saved to: $OutFile"
Write-Host "    SHA256: $Hash"
Write-Host ""

# -------------------------
# 5) Install
# -------------------------
Write-Host "[5] Installing..."

if ($AssetType -eq 'setup') {

    if ([string]::IsNullOrWhiteSpace($InstallArgs)) {
        Write-Host "    Launching installer interactively..."
        $p = Start-Process -FilePath $OutFile -Wait -PassThru
    }
    else {
        Write-Host "    Launching installer with args: $InstallArgs"
        $p = Start-Process -FilePath $OutFile -ArgumentList $InstallArgs -Wait -PassThru
    }

    if ($p.ExitCode -ne 0) {
        throw "Installer exited with code $($p.ExitCode)"
    }

    Write-Host "    Installation completed successfully."
}
else {
    $Target = Join-Path $env:ProgramFiles 'PARennialGolf\BayManagement'
    Write-Host "    Extracting to $Target..."

    New-Item -ItemType Directory -Force -Path $Target | Out-Null
    Expand-Archive -Path $OutFile -DestinationPath $Target -Force

    Write-Host "    Portable version extracted."
}

Write-Host ""
Write-Host "=== Install Finished Successfully ==="
