@echo off
setlocal EnableDelayedExpansion

:: Set variables
set "TPS_URL=https://link.trackman.dk/tpsrelease"
set "DOWNLOADS_DIR=%USERPROFILE%\Downloads"
set "INSTALLER=%DOWNLOADS_DIR%\TrackManPerformanceStudioSetup.exe"
set "LOG_FILE=%DOWNLOADS_DIR%\install_tps.log"
set "TPS_EXE=C:\Program Files\TrackMan Performance Studio\TrackMan Performance Studio.exe"

:: Log start
echo [%DATE% %TIME%] Starting TPS installation >> "%LOG_FILE%"
echo Starting TPS installation...

:: Check for curl
curl --version >nul 2>&1 || (
    echo [%DATE% %TIME%] ERROR: curl not found. Download from https://curl.se/windows/ >> "%LOG_FILE%"
    echo ERROR: curl not found. Download from https://curl.se/windows/
    exit /b 1
)

:: Check if TPS is installed
echo [%DATE% %TIME%] Checking for TPS at %TPS_EXE%... >> "%LOG_FILE%"
if exist "%TPS_EXE%" (
    echo [%DATE% %TIME%] TPS already installed at %TPS_EXE%. Exiting. >> "%LOG_FILE%"
    echo TPS already installed at %TPS_EXE%. Exiting.
    exit /b 0
)
echo [%DATE% %TIME%] TPS not found. Proceeding with download. >> "%LOG_FILE%"

:: Download installer
echo [%DATE% %TIME%] Downloading TPS installer to %INSTALLER%... >> "%LOG_FILE%"
curl -L -o "%INSTALLER%" "%TPS_URL%"
if %ERRORLEVEL% neq 0 (
    echo [%DATE% %TIME%] ERROR: Failed to download TPS installer. >> "%LOG_FILE%"
    echo ERROR: Failed to download TPS installer.
    exit /b 1
)
echo [%DATE% %TIME%] Download complete. >> "%LOG_FILE%"

:: Run installer (non-silent)
echo [%DATE% %TIME%] Running TPS installer (non-silent)... >> "%LOG_FILE%"
start /wait "" "%INSTALLER%"
echo [%DATE% %TIME%] TPS installation completed. >> "%LOG_FILE%"

echo TPS installation completed successfully.
exit /b 0