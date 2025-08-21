param(
  [Parameter(Mandatory = $true)] [string]$Token,            # GitHub PAT
  [string]$Owner = 'parennialgolf',
  [string]$Repo  = 'dotnet',
  [ValidateSet('setup','portable')] [string]$AssetType = 'setup',
  [switch]$IncludePrerelease,
  [string]$InstallArgs = ''                                # e.g. '--silent --installto "C:\Program Files\PARennialGolf\BayManagement"'
)

$ErrorActionPreference = 'Stop'
$ProgressPreference    = 'SilentlyContinue'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

Write-Host "=== Bay Management Installer ==="
Write-Host "Owner:    $Owner"
Write-Host "Repo:     $Repo"
Write-Host "Type:     $AssetType"
Write-Host "Prerelease included: $IncludePrerelease"
Write-Host ""

# --- 0) Check if already installed ---
$ExePath = Join-Path $env:LOCALAPPDATA 'PARennialGolf.BayManagement.UI.V2\current\PARennialGolf.BayManagement.UI.V2.exe'

if (Test-Path $ExePath) {
    Write-Host ">>> Bay Management already installed at $ExePath"
    Write-Host ">>> Skipping download and install."
    exit 0
}

# --- API setup ---
$ApiBase = "https://api.github.com/repos/$Owner/$Repo"
$Headers = @{
  Authorization          = "Bearer $Token"
  'User-Agent'           = 'pg-installer'
  Accept                 = 'application/vnd.github+json'
  'X-GitHub-Api-Version' = '2022-11-28'
}

# --- 1) Find newest release ---
Write-Host "[1] Fetching releases from GitHub..."
$Releases = Invoke-RestMethod -Headers $Headers -Uri "$ApiBase/releases?per_page=30"
$Releases = $Releases | Where-Object { -not $_.draft }
if (-not $IncludePrerelease) { $Releases = $Releases | Where-Object { -not $_.prerelease } }
if (-not $Releases) { throw "No published releases visible to this token." }

$Release = $Releases | Sort-Object -Property @{ Expression = {
  if ($_.published_at) { Get-Date $_.published_at } else { Get-Date $_.created_at }
}} -Descending | Select-Object -First 1

Write-Host "    Selected release: $($Release.tag_name) ($($Release.name))"
Write-Host ""

# --- 2) Pick the asset ---
Write-Host "[2] Choosing asset..."
$Preferred = if ($AssetType -eq 'setup') { 'PARennialGolf.BayManagement.UI.V2-win-Setup.exe' }
             else { 'PARennialGolf.BayManagement.UI.V2-win-Portable.zip' }

$ReleaseAsset = $Release.assets | Where-Object { $_.name -eq $Preferred } | Select-Object -First 1
if (-not $ReleaseAsset) {
  $Pattern = if ($AssetType -eq 'setup') { '*-win-Setup.exe' } else { '*-win-Portable.zip' }
  $ReleaseAsset = $Release.assets | Where-Object { $_.name -like $Pattern } | Select-Object -First 1
}
if (-not $ReleaseAsset) {
  $names = ($Release.assets | ForEach-Object { $_.name }) -join ', '
  throw "Asset not found. Looked for '$Preferred' or pattern. Assets available: $names"
}

Write-Host "    Asset chosen: $($ReleaseAsset.name)"
Write-Host ""

# --- 3) Resolve redirect ---
Write-Host "[3] Resolving signed download URL..."
Add-Type -AssemblyName System.Net.Http
$Handler = New-Object System.Net.Http.HttpClientHandler
$Handler.AllowAutoRedirect = $false
$Client  = New-Object System.Net.Http.HttpClient($Handler)
$Client.DefaultRequestHeaders.UserAgent.ParseAdd('pg-installer')
$Client.DefaultRequestHeaders.Authorization =
  New-Object System.Net.Http.Headers.AuthenticationHeaderValue('Bearer', $Token)
$Client.DefaultRequestHeaders.Accept.Clear()
$Client.DefaultRequestHeaders.Accept.Add(
  [System.Net.Http.Headers.MediaTypeWithQualityHeaderValue]::new('application/octet-stream'))

$ApiAssetUrl = "$ApiBase/releases/assets/$($ReleaseAsset.id)"
$Request  = New-Object System.Net.Http.HttpRequestMessage([System.Net.Http.HttpMethod]::Get, $ApiAssetUrl)
$Response = $Client.SendAsync($Request).Result

$Redirect = $null
if ($Response -and $Response.Headers.Location) {
  $Redirect = $Response.Headers.Location
  if (-not $Redirect.IsAbsoluteUri) { $Redirect = [Uri]::new($ApiAssetUrl, $Redirect) }
}
if (-not $Redirect) { throw "Could not resolve redirect URL for asset $($ReleaseAsset.name)." }

Write-Host "    Redirect resolved: $Redirect"
Write-Host ""

# --- 4) Download ---
Write-Host "[4] Downloading asset..."
$OutFile = Join-Path $env:TEMP $ReleaseAsset.name
Invoke-WebRequest -Uri $Redirect.AbsoluteUri -OutFile $OutFile -MaximumRedirection 5 -TimeoutSec 600

$Hash = (Get-FileHash -Algorithm SHA256 -Path $OutFile).Hash
Write-Host "    Saved to: $OutFile"
Write-Host "    SHA256:  $Hash"
Write-Host ""

# --- 5) Install / extract ---
Write-Host "[5] Installing..."
if ($InstallArgs -match '(^|\s)/S(\s|$)') { 
    $InstallArgs = $InstallArgs -replace '(^|\s)/S(\s|$)',' --silent ' 
}

if ($AssetType -eq 'setup') {
  if ([string]::IsNullOrWhiteSpace($InstallArgs)) {
    Write-Host "    Launching installer interactively..."
    $p = Start-Process -FilePath $OutFile -Wait -PassThru
  } else {
    Write-Host "    Launching installer with args: $InstallArgs"
    $p = Start-Process -FilePath $OutFile -ArgumentList $InstallArgs -Wait -PassThru
  }
  if ($p.ExitCode -ne 0) { throw "Installer exited with code $($p.ExitCode)" }
  Write-Host "    Bay Management installation complete."
} else {
  $Target = Join-Path ${env:ProgramFiles} 'PARennialGolf\BayManagement'
  Write-Host "    Extracting to $Target..."
  New-Item -ItemType Directory -Force -Path $Target | Out-Null
  Expand-Archive -Path $OutFile -DestinationPath $Target -Force
  Write-Host "    Bay Management extracted successfully."
}

Write-Host ""
Write-Host "=== Install Finished Successfully ==="
