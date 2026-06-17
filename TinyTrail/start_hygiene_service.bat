@echo off
REM TinyTrails Hygiene Service Launcher for Windows
REM This script starts the hygiene AI service automatically

echo ==========================================
echo   TinyTrails Hygiene Service Launcher
echo ==========================================
echo.

cd /d "T:\College\Project\TinyTrail\hygiene_service"

REM Check if Python is available
python --version >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Python is not installed or not in PATH
    echo Please install Python 3.8+ and try again
    pause
    exit /b 1
)

REM Check if required packages are installed
echo [INFO] Checking dependencies...
python -c "import fastapi, torch, torchvision, PIL" >nul 2>&1
if errorlevel 1 (
    echo [INFO] Installing required packages...
    pip install -r requirements.txt
    if errorlevel 1 (
        echo [ERROR] Failed to install dependencies
        pause
        exit /b 1
    )
)

echo.
echo [INFO] Starting Hygiene Service on http://localhost:8000
echo [INFO] Press Ctrl+C to stop the service
echo.

python app_unified.py
