# PARennial Golf Installers

This repository contains automated installation scripts for PARennial Golf applications. These scripts simplify the process of downloading and installing the latest versions of Bay Management and TrackMan Performance Studio (TPS) software.

## 📋 Scripts Overview

### 1. `bay-management.ps1` - Bay Management PowerShell Installer

A comprehensive PowerShell script that automatically downloads and installs the latest Bay Management application from GitHub releases.

**Features:**
- ✅ **Smart Detection**: Checks if Bay Management is already installed before proceeding
- 🔄 **Automatic Updates**: Fetches the latest release from GitHub API
- 🛡️ **Secure Downloads**: Uses GitHub Personal Access Token (PAT) for authenticated API access
- 📦 **Multiple Installation Types**: Supports both setup (.exe) and portable (.zip) installations
- 🎯 **Flexible Configuration**: Customizable installation arguments and target directories
- 📝 **Comprehensive Logging**: Detailed output with progress tracking and error handling

**Usage:**
```powershell
# Basic installation with setup executable
.\bay-management.ps1 -Token "your_github_pat_here"

# Install portable version
.\bay-management.ps1 -Token "your_github_pat_here" -AssetType portable

# Install with custom arguments (silent install)
.\bay-management.ps1 -Token "your_github_pat_here" -InstallArgs "--silent"

# Include pre-release versions
.\bay-management.ps1 -Token "your_github_pat_here" -IncludePrerelease
```

**Parameters:**
- `Token` (Required): GitHub Personal Access Token for API access
- `Owner`: GitHub repository owner (default: 'parennialgolf')
- `Repo`: GitHub repository name (default: 'dotnet')
- `AssetType`: Installation type - 'setup' or 'portable' (default: 'setup')
- `IncludePrerelease`: Include pre-release versions in selection
- `InstallArgs`: Additional arguments to pass to the installer

**Installation Path:**
- Default: `%LOCALAPPDATA%\PARennialGolf.BayManagement.UI.V2\current\`
- Portable: `%ProgramFiles%\PARennialGolf\BayManagement\`

### 2. `tps.bat` - TrackMan Performance Studio Batch Installer

A Windows batch script that downloads and installs TrackMan Performance Studio software.

**Features:**
- 🔍 **Pre-installation Check**: Verifies if TPS is already installed
- 📥 **Direct Download**: Downloads installer from TrackMan's official release URL
- 📝 **Activity Logging**: Creates detailed log files for troubleshooting
- ⚡ **Dependency Validation**: Checks for required tools (curl)
- 🎮 **Interactive Installation**: Runs installer in interactive mode for user control

**Usage:**
```batch
# Run the installer
tps.bat
```

**Requirements:**
- Windows operating system
- `curl` command-line tool (checks automatically)
- Internet connection

**Installation Details:**
- **Download URL**: https://link.trackman.dk/tpsrelease
- **Download Location**: `%USERPROFILE%\Downloads\TrackManPerformanceStudioSetup.exe`
- **Installation Path**: `C:\Program Files\TrackMan Performance Studio\`
- **Log File**: `%USERPROFILE%\Downloads\install_tps.log`

### 3. `remote-install.bat` - Remote Batch Installer

A Windows batch script that downloads and executes installer scripts directly from the GitHub repository.

**Features:**
- 🌐 **Remote Execution**: Downloads and runs scripts directly from GitHub
- 🔄 **Multi-Script Support**: Can execute either Bay Management or TPS installers
- 📝 **Comprehensive Logging**: Detailed logging with timestamps
- 🧹 **Automatic Cleanup**: Removes temporary files after execution
- 🛡️ **Error Handling**: Robust error checking and validation

## 🌐 Remote Execution

For one-command installation from any Windows machine with internet access, use curl to download and execute the scripts directly:

```batch
# Download and run the remote installer
curl -L -o remote-install.bat https://raw.githubusercontent.com/parennialgolf/installers/main/remote-install.bat

# Install Bay Management
remote-install.bat bay-management YOUR_GITHUB_TOKEN

# Install Bay Management with custom arguments
remote-install.bat bay-management YOUR_GITHUB_TOKEN --silent
remote-install.bat bay-management YOUR_GITHUB_TOKEN -AssetType portable

# Install TPS (no token needed)
remote-install.bat tps
```

### Method 1: Download and Execute Remote Installer

```batch
# Download the remote installer
curl -L -o remote-install.bat https://raw.githubusercontent.com/parennialgolf/installers/main/remote-install.bat

# Install Bay Management
remote-install.bat bay-management YOUR_GITHUB_TOKEN

# Install TPS (no token needed)
remote-install.bat tps
```

### Method 2: Direct Script Execution

**Bay Management:**
```batch
# Download and run directly
curl -L -o bay-management.ps1 https://raw.githubusercontent.com/parennialgolf/installers/main/bay-management.ps1
powershell.exe -ExecutionPolicy Bypass -File bay-management.ps1 -Token "YOUR_GITHUB_TOKEN"
```

**TPS:**
```batch
# Download and run directly
curl -L -o tps.bat https://raw.githubusercontent.com/parennialgolf/installers/main/tps.bat
tps.bat
```

### Method 3: One-Liner Commands

**Bay Management:**
```batch
curl -L -o temp-bay.ps1 https://raw.githubusercontent.com/parennialgolf/installers/main/bay-management.ps1 && powershell.exe -ExecutionPolicy Bypass -File temp-bay.ps1 -Token "YOUR_GITHUB_TOKEN" && del temp-bay.ps1
```

**TPS:**
```batch
curl -L -o temp-tps.bat https://raw.githubusercontent.com/parennialgolf/installers/main/tps.bat && temp-tps.bat && del temp-tps.bat
```

## 🚀 Quick Start

### Prerequisites

1. **For Bay Management (`bay-management.ps1`)**:
   - PowerShell 5.0 or later
   - GitHub Personal Access Token with repository read access
   - Internet connection

2. **For TPS (`tps.bat`)**:
   - Windows operating system
   - curl command-line tool
   - Internet connection

### Creating a GitHub Personal Access Token

To use the Bay Management installer, you'll need a GitHub PAT:

1. Go to GitHub → Settings → Developer settings → Personal access tokens → Tokens (classic)
2. Click "Generate new token (classic)"
3. Give it a descriptive name
4. Select the `repo` scope for private repositories or `public_repo` for public repositories
5. Click "Generate token"
6. Copy the token and use it with the `-Token` parameter

## 🛠️ Technical Details

### Bay Management Script Architecture

The PowerShell script follows a structured approach:

1. **Validation Phase**: Checks if software is already installed
2. **API Integration**: Authenticates with GitHub API using PAT
3. **Release Selection**: Finds the latest stable or pre-release version
4. **Asset Resolution**: Selects appropriate installer type (setup/portable)
5. **Secure Download**: Handles GitHub's signed URL redirects
6. **Installation**: Executes installer with optional custom arguments

### Error Handling

Both scripts include comprehensive error handling:
- Network connectivity issues
- Authentication failures
- File download errors
- Installation process failures
- Missing dependencies

## 📄 Logs and Troubleshooting

### Bay Management
- Outputs detailed progress information to console
- Error messages include specific failure points
- SHA256 hash verification for downloaded files

### TPS Installation
- Creates log file: `%USERPROFILE%\Downloads\install_tps.log`
- Timestamps all operations
- Records download and installation status

## 🔒 Security Notes

- GitHub PAT should be kept secure and not shared
- Scripts verify file integrity using SHA256 hashing
- All downloads use HTTPS/TLS 1.2 encryption
- No sensitive information is logged in plain text

## 📞 Support

For issues with these installers, please check the log files first. Common solutions:

1. **GitHub API Issues**: Verify your PAT has correct permissions
2. **Download Failures**: Check internet connection and firewall settings
3. **Installation Errors**: Run as administrator if needed
4. **curl Not Found**: Install curl from https://curl.se/windows/

## 📝 License

These installer scripts are provided as-is for PARennial Golf software deployment.
