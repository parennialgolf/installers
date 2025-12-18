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

### 3. `install.bat` - Universal Installer (⭐ Recommended)

A single batch file that can install either Bay Management or TPS applications by downloading and executing the appropriate installer scripts.

**Features:**
- 🎯 **Single Entry Point**: One script handles both applications  
- 🌐 **Remote Ready**: Designed for curl-based execution
- 🔍 **Smart Detection**: Checks if software is already installed
- 📥 **Auto-Download**: Fetches the appropriate installer script as needed
- 📝 **Comprehensive Logging**: Detailed logging with timestamps
- 🧹 **Auto-Cleanup**: Removes temporary files after execution
- 🛡️ **Error Handling**: Robust validation and error reporting

**Usage:**
```batch
# Local usage
install.bat bay-management YOUR_GITHUB_TOKEN
install.bat tps  
install.bat both YOUR_GITHUB_TOKEN

# Remote usage (see One-Command Installation section above)
```

## 🚀 One-Command Installation

Install PARennial Golf applications with a single command from any Windows machine with internet access.

### 🎯 **Quick Commands**

**Install Bay Management Only:**
```batch
curl -s https://raw.githubusercontent.com/parennialgolf/installers/main/install.bat > temp-install.bat && temp-install.bat bay-management YOUR_GITHUB_TOKEN && del temp-install.bat
```

**Install TPS Only:**
```batch
curl -s https://raw.githubusercontent.com/parennialgolf/installers/main/install.bat > temp-install.bat && temp-install.bat tps && del temp-install.bat
```

**Install Both Applications (Bay Management → TPS):**
```batch
curl -s https://raw.githubusercontent.com/parennialgolf/installers/main/install.bat > temp-install.bat && temp-install.bat both YOUR_GITHUB_TOKEN && del temp-install.bat
```

### 📋 **How to Use**

1. **Replace `YOUR_GITHUB_TOKEN`** with your actual GitHub Personal Access Token
2. **Copy and paste** the entire command into Windows Command Prompt
3. **Press Enter** and the installer will:
   - Download the universal installer
   - Execute the installation(s)
   - Clean up temporary files automatically

### ⚡ **What Each Command Does**

- **Bay Management**: Downloads and installs the latest Bay Management application (requires PARennial Golf GitHub access)
- **TPS**: Downloads and installs TrackMan Performance Studio (no special access required - anyone can use)
- **Both**: Installs Bay Management first, then TPS (requires PARennial Golf GitHub access for Bay Management portion)

### 🔧 **Requirements**

- Windows operating system with Command Prompt
- `curl` command-line tool (pre-installed on Windows 10/11)
- **PARennial Golf GitHub Personal Access Token** (for Bay Management only)
- Internet connection

**Note**: Bay Management requires a GitHub token with access to the PARennial Golf organization. TPS installation works for anyone without special permissions.

### 🔑 **Creating a PARennial Golf GitHub Personal Access Token**

**Requirements**: You must have access to the PARennial Golf GitHub organization.

You can use either **fine-grained** tokens (`github_pat_...`) or **classic** tokens (`ghp_...`).

**Fine-grained (recommended):**
1. Go to **GitHub → Settings → Developer settings → Personal access tokens → Fine-grained tokens**
2. Create a token with **Repository access** including the Bay Management repo (default in script: `parennialgolf/dotnet`)
3. Set **Permissions** to at least **Contents: Read**
4. If your org uses SAML SSO, **Authorize SSO** for the token

**Classic (works):**
1. Go to **GitHub → Settings → Developer settings → Personal access tokens → Tokens (classic)**
2. Click **"Generate new token (classic)"**
3. Give it a descriptive name (e.g., "PARennial Golf Installer")
4. Select the **`repo`** scope to access private repositories
5. If your org uses SAML SSO, **Authorize SSO**
6. **Copy the token** and use it in the Bay Management commands above

⚠️ **Security note**: Don’t paste tokens into chat/tickets. Prefer setting an environment variable and referencing it from the command line.

**Note**: If you don't have access to PARennial Golf repositories, contact your administrator for access or use only the TPS installer.

## 📞 **Support**

If you encounter issues:

1. **GitHub Token Error**: Verify your PAT has `repo` permissions and access to PARennial Golf organization
2. **Download Failures**: Check your internet connection and firewall settings
3. **Installation Errors**: Try running Command Prompt as administrator
4. **curl Not Found**: Install curl from https://curl.se/windows/ (usually pre-installed on Windows 10/11)

## 📝 **License**

These installer scripts are provided as-is for PARennial Golf software deployment.
