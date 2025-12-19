param(
  [Parameter(Mandatory = $true)]
  [string]$Token,                              # GitHub classic or fine-grained PAT

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

Write-Host '=== Bay Management Installer ==='
Write-Host ('Owner:    {0}' -f $Owner)
Write-Host ('Repo:     {0}' -f $Repo)
Write-Host ('Type:     {0}' -f $AssetType)
Write-Host ('Prerelease included: {0}' -f $IncludePrerelease)
Write-Host ''

# -------------------------
# 0) Already installed?
# -------------------------
$ExePath = Join-Path $env:LOCALAPPDATA 'PARennialGolf.BayManagement.UI.V2\current\PARennialGolf.BayManagement.UI.V2.exe'

if (Test-Path $ExePath) {
    Write-Host '>>> Bay Management already installed:'
    Write-Host ('>>> {0}' -f $ExePath)
    Write-Host '>>> Skipping install.'
    exit 0
}

# -------------------------
# GitHub API setup
# -------------------------
$RepoApi = "https://api.github.com/repos/$Owner/$Repo"

$Headers = @{
  # Use Bearer for maximum compatibility (fine-grained PATs require it; classic PATs also work).
  Authorization          = "Bearer $Token"
  'User-Agent'           = 'pg-installer'
  Accept                 = 'application/vnd.github+json'
  'X-GitHub-Api-Version' = '2022-11-28'
}

# -------------------------
# Preflight: repo access
# -------------------------
Write-Host "[0] Verifying repository access..."
try {
    Invoke-RestMethod -Headers $Headers -Uri $RepoApi -Method Get | Out-Null
}
catch {
    $status = $null
    try { $status = $_.Exception.Response.StatusCode.value__ } catch { }

    $extraLines =
      if ($status -eq 404) {
        @(
          'GitHub returned 404 for the repo API.'
          'This usually means one of:'
          '- The repository name is wrong (repo does not exist), OR'
          '- The repo is private and your token is missing access (GitHub often returns 404 for unauthorized private repos).'
          ''
          'For fine-grained tokens (github_pat_...), ensure:'
          "- Repository access includes $Owner/$Repo"
          '- Permissions include at least Contents: Read'
          '- If the org uses SAML SSO, the token is authorized for SSO'
        )
      }
      elseif ($status -eq 401 -or $status -eq 403) {
        @(
          "GitHub returned $status (unauthorized/forbidden)."
          'Ensure:'
          '- Token is valid (not expired/revoked)'
          "- Token has access to $Owner/$Repo"
          '- If the org uses SAML SSO, the token is authorized for SSO'
        )
      }
      else {
        @("GitHub error status: $status")
      }

    $extra = $extraLines -join [Environment]::NewLine

    $nl = [Environment]::NewLine
    throw ("Cannot access repository {0}/{1}{4}URL: {2}{4}{4}{3}" -f $Owner, $Repo, $RepoApi, $extra, $nl)
}

# -------------------------
# 1) Fetch releases
# -------------------------
Write-Host "[1] Fetching releases..."
$ReleasesUrl = "$RepoApi/releases?per_page=30"
Write-Host ('    URL: {0}' -f $ReleasesUrl)

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

Write-Host ('    Selected release: {0} - {1}' -f $Release.tag_name, $Release.name)
Write-Host ''

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

Write-Host ('    Asset chosen: {0}' -f $Asset.name)
Write-Host ''

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
    New-Object System.Net.Http.Headers.AuthenticationHeaderValue('Bearer', $Token)

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
Write-Host '    Download URL resolved.'
Write-Host ''

# -------------------------
# 4) Download
# -------------------------
Write-Host "[4] Downloading asset..."
$OutFile = Join-Path $env:TEMP $Asset.name

Invoke-WebRequest -Uri $DownloadUrl -OutFile $OutFile -MaximumRedirection 5 -TimeoutSec 600

$Hash = (Get-FileHash -Algorithm SHA256 -Path $OutFile).Hash
Write-Host ('    Saved to: {0}' -f $OutFile)
Write-Host ('    SHA256: {0}' -f $Hash)
Write-Host ''

# -------------------------
# 5) Install
# -------------------------
Write-Host "[5] Installing..."

if ($AssetType -eq 'setup') {

    if ([string]::IsNullOrWhiteSpace($InstallArgs)) {
        Write-Host '    Launching installer interactively...'
        $p = Start-Process -FilePath $OutFile -Wait -PassThru
    }
    else {
        Write-Host ('    Launching installer with args: {0}' -f $InstallArgs)
        $p = Start-Process -FilePath $OutFile -ArgumentList $InstallArgs -Wait -PassThru
    }

    if ($p.ExitCode -ne 0) {
        throw "Installer exited with code $($p.ExitCode)"
    }

    Write-Host '    Installation completed successfully.'
}
else {
    $Target = Join-Path $env:ProgramFiles 'PARennialGolf\BayManagement'
    Write-Host ('    Extracting to {0}...' -f $Target)

    New-Item -ItemType Directory -Force -Path $Target | Out-Null
    Expand-Archive -Path $OutFile -DestinationPath $Target -Force

    Write-Host '    Portable version extracted.'
}

Write-Host ''
Write-Host '=== Install Finished Successfully ==='
