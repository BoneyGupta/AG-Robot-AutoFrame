@echo off
setlocal EnableDelayedExpansion

echo ============================================================
echo  AG Robot AutoFrame Framework - Environment Setup
echo ============================================================
echo.

:: -- Configuration --
set PYTHON_VERSION=3.11.9
set PYTHON_INSTALLER=python-%PYTHON_VERSION%-amd64.exe
set PYTHON_URL=https://www.python.org/ftp/python/%PYTHON_VERSION%/%PYTHON_INSTALLER%
set PYTHON_INSTALL_DIR=C:\Python%PYTHON_VERSION:.=%
set REQUIREMENTS_FILE=%~dp0requirements.txt

:: -- Step 1: Check if Python is already installed --
echo [1/4] Checking for Python installation...
echo.

python --version >nul 2>&1
if %errorlevel% equ 0 (
    for /f "tokens=2 delims= " %%v in ('python --version 2^>^&1') do set FOUND_VERSION=%%v
    echo       Python !FOUND_VERSION! found.
    echo.
    goto :CHECK_PIP
)

py --version >nul 2>&1
if %errorlevel% equ 0 (
    for /f "tokens=2 delims= " %%v in ('py --version 2^>^&1') do set FOUND_VERSION=%%v
    echo       Python !FOUND_VERSION! found via py launcher.
    echo.
    goto :CHECK_PIP
)

echo       Python NOT found. Proceeding to download and install...
echo.

:: -- Step 2: Download Python installer --
echo [2/4] Downloading Python %PYTHON_VERSION%...
echo       URL: %PYTHON_URL%
echo.

set TEMP_INSTALLER=%TEMP%\%PYTHON_INSTALLER%

:: Try PowerShell download
powershell -Command "& { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -Uri '%PYTHON_URL%' -OutFile '%TEMP_INSTALLER%' -UseBasicParsing }" 2>nul

if not exist "%TEMP_INSTALLER%" (
    :: Fallback to certutil
    echo       PowerShell download failed, trying certutil...
    certutil -urlcache -split -f "%PYTHON_URL%" "%TEMP_INSTALLER%" >nul 2>&1
)

if not exist "%TEMP_INSTALLER%" (
    echo.
    echo  ERROR: Failed to download Python installer.
    echo         Please download manually from https://www.python.org/downloads/
    echo.
    pause
    exit /b 1
)

echo       Download complete: %TEMP_INSTALLER%
echo.

:: -- Step 3: Install Python silently --
echo [3/4] Installing Python %PYTHON_VERSION%...
echo       Install directory: %PYTHON_INSTALL_DIR%
echo       This may take a few minutes...
echo.

"%TEMP_INSTALLER%" /quiet InstallAllUsers=1 TargetDir="%PYTHON_INSTALL_DIR%" PrependPath=1 Include_test=0 Include_launcher=1 AssociateFiles=1

if %errorlevel% neq 0 (
    echo.
    echo  ERROR: Python installation failed (exit code: %errorlevel%).
    echo         Try running this script as Administrator.
    echo.
    del "%TEMP_INSTALLER%" >nul 2>&1
    pause
    exit /b 1
)

echo       Python installed successfully.
echo.

:: Clean up installer
del "%TEMP_INSTALLER%" >nul 2>&1

:: -- Update PATH for current session --
echo       Updating PATH for current session...
set "PATH=%PYTHON_INSTALL_DIR%;%PYTHON_INSTALL_DIR%\Scripts;%PATH%"

:: Also update system PATH permanently via PowerShell
powershell -Command "& { $currentPath = [Environment]::GetEnvironmentVariable('Path', 'Machine'); if ($currentPath -notlike '*%PYTHON_INSTALL_DIR%*') { [Environment]::SetEnvironmentVariable('Path', '%PYTHON_INSTALL_DIR%;%PYTHON_INSTALL_DIR%\Scripts;' + $currentPath, 'Machine') } }" 2>nul

:: Verify installation
python --version >nul 2>&1
if %errorlevel% neq 0 (
    echo.
    echo  WARNING: Python installed but not yet in PATH.
    echo           Please restart your terminal and run this script again.
    echo.
    pause
    exit /b 1
)

for /f "tokens=2 delims= " %%v in ('python --version 2^>^&1') do set FOUND_VERSION=%%v
echo       Verified: Python !FOUND_VERSION! is now available.
echo.

:CHECK_PIP
:: -- Step 3b: Check pip --
echo [3/4] Checking pip...
echo.

python -m pip --version >nul 2>&1
if %errorlevel% neq 0 (
    echo       pip not found. Installing pip...
    python -m ensurepip --upgrade >nul 2>&1
    if %errorlevel% neq 0 (
        echo  ERROR: Failed to install pip.
        pause
        exit /b 1
    )
)

:: Upgrade pip silently
python -m pip install --upgrade pip >nul 2>&1

for /f "tokens=2 delims= " %%v in ('python -m pip --version 2^>^&1') do set PIP_VERSION=%%v
echo       pip %PIP_VERSION% is available.
echo.

:: -- Step 4: Install dependencies from requirements.txt --
echo [4/4] Installing dependencies from requirements.txt...
echo.

if not exist "%REQUIREMENTS_FILE%" (
    echo  ERROR: requirements.txt not found at:
    echo         %REQUIREMENTS_FILE%
    echo.
    pause
    exit /b 1
)

echo       Contents of requirements.txt:
echo       -----------------------------
for /f "usebackq delims=" %%l in ("%REQUIREMENTS_FILE%") do (
    echo         %%l
)
echo       -----------------------------
echo.

python -m pip install -r "%REQUIREMENTS_FILE%"

if %errorlevel% neq 0 (
    echo.
    echo  ERROR: Failed to install some dependencies.
    echo         Check the output above for details.
    echo.
    pause
    exit /b 1
)

echo.
echo ============================================================
echo  Setup Complete!
echo ============================================================
echo.
echo  Python:    !FOUND_VERSION!
for /f "tokens=2 delims= " %%v in ('python -m pip --version 2^>^&1') do echo  pip:       %%v
echo.
echo  Installed packages:
echo  -----------------------------
python -m pip list --format=columns 2>nul | findstr /i "robotframework selenium lxml"
echo  -----------------------------
echo.
echo  You can now run tests with:
echo    test_e2e.bat
echo    test_browser.bat
echo    test_stepIterator.bat
echo.
echo ============================================================
pause
