@echo off
setlocal EnableDelayedExpansion

:: Universal PARennial Golf Installer
:: Usage: install.bat [bay-management|tps] [github_token]

:: Handle command line args or environment variables for remote execution
if "%~1"=="" (
    if "%PG_APP%"=="" (
        echo.
        echo === PARennial Golf Universal Installer ===
        echo.
        echo Usage: install.bat [application] [token]
        echo.
        echo Applications:
        echo   bay-management  - Install Bay Management ^(requires GitHub token^)
        echo   tps            - Install TrackMan Performance Studio ^(no token needed^)
        echo.
        echo Examples:
        echo   install.bat bay-management ghp_xxxxxxxxxxxx
        echo   install.bat tps
        echo.
        echo Remote usage:
        echo   curl -s https://raw.githubusercontent.com/parennialgolf/installers/main/install.bat ^> temp-install.bat ^&^& temp-install.bat bay-management YOUR_TOKEN ^&^& del temp-install.bat
        echo   curl -s https://raw.githubusercontent.com/parennialgolf/installers/main/install.bat ^> temp-install.bat ^&^& temp-install.bat tps ^&^& del temp-install.bat
        echo.
        exit /b 1
    ) else (
        set "APP_TYPE=%PG_APP%"
        set "GITHUB_TOKEN=%PG_TOKEN%"
        goto :start_install
    )
) else (
    set "APP_TYPE=%~1"
    set "GITHUB_TOKEN=%~2"
    goto :start_install
)

:start_install
set "REPO_URL=https://raw.githubusercontent.com/parennialgolf/installers/main"
set "TEMP_DIR=%TEMP%\pg-installer"
set "LOG_FILE=%TEMP_DIR%\install.log"

:: Create temp directory
if not exist "%TEMP_DIR%" mkdir "%TEMP_DIR%"

:: Log function (writes to both console and file)
goto :skip_log_func
:log
echo [%DATE% %TIME%] %~1 >> "%LOG_FILE%"
echo %~1
exit /b 0
:skip_log_func

call :log "=== PARennial Golf Universal Installer ==="
call :log "Application: %APP_TYPE%"
call :log "Temp Directory: %TEMP_DIR%"
call :log ""

:: Check for curl
curl --version >nul 2>&1 || (
    call :log "ERROR: curl is required but not found."
    call :log "Please install curl from https://curl.se/windows/"
    exit /b 1
)

:: Route to appropriate installer
if /i "%APP_TYPE%"=="bay-management" (
    goto :install_bay_management
) else if /i "%APP_TYPE%"=="tps" (
    goto :install_tps
) else (
    call :log "ERROR: Unknown application type '%APP_TYPE%'"
    call :log "Valid options: bay-management, tps"
    exit /b 1
)

:install_bay_management
call :log "Installing Bay Management..."

if "%GITHUB_TOKEN%"=="" (
    call :log "ERROR: GitHub token is required for Bay Management installation"
    call :log "Usage: install.bat bay-management YOUR_GITHUB_TOKEN"
    exit /b 1
)

:: Check if already installed
set "BAY_EXE=%LOCALAPPDATA%\PARennialGolf.BayManagement.UI.V2\current\PARennialGolf.BayManagement.UI.V2.exe"
if exist "%BAY_EXE%" (
    call :log "Bay Management already installed at %BAY_EXE%"
    call :log "Skipping installation."
    exit /b 0
)

call :log "Downloading Bay Management installer script..."
set "SCRIPT_FILE=%TEMP_DIR%\bay-management.ps1"
curl -L -s -o "%SCRIPT_FILE%" "%REPO_URL%/bay-management.ps1"
if %ERRORLEVEL% neq 0 (
    call :log "ERROR: Failed to download bay-management.ps1"
    exit /b 1
)

call :log "Script downloaded successfully."
call :log "Executing Bay Management installer..."

powershell.exe -ExecutionPolicy Bypass -File "%SCRIPT_FILE%" -Token "%GITHUB_TOKEN%"
set "EXIT_CODE=%ERRORLEVEL%"

if %EXIT_CODE% equ 0 (
    call :log "=== Bay Management Installation Complete ==="
) else (
    call :log "ERROR: Bay Management installation failed (Exit Code: %EXIT_CODE%)"
)

goto :cleanup

:install_tps
call :log "Installing TrackMan Performance Studio..."

:: Check if already installed
set "TPS_EXE=C:\Program Files\TrackMan Performance Studio\TrackMan Performance Studio.exe"
if exist "%TPS_EXE%" (
    call :log "TPS already installed at %TPS_EXE%"
    call :log "Skipping installation."
    exit /b 0
)

call :log "Downloading TPS installer script..."
set "SCRIPT_FILE=%TEMP_DIR%\tps.bat"
curl -L -s -o "%SCRIPT_FILE%" "%REPO_URL%/tps.bat"
if %ERRORLEVEL% neq 0 (
    call :log "ERROR: Failed to download tps.bat"
    exit /b 1
)

call :log "Script downloaded successfully."
call :log "Executing TPS installer..."

call "%SCRIPT_FILE%"
set "EXIT_CODE=%ERRORLEVEL%"

if %EXIT_CODE% equ 0 (
    call :log "=== TPS Installation Complete ==="
) else (
    call :log "ERROR: TPS installation failed (Exit Code: %EXIT_CODE%)"
)

goto :cleanup

:cleanup
call :log "Cleaning up temporary files..."
if exist "%SCRIPT_FILE%" del /q "%SCRIPT_FILE%"

call :log "Installation process finished with exit code %EXIT_CODE%"
call :log "Log file saved to: %LOG_FILE%"
exit /b %EXIT_CODE%
