@echo off
REM TinyTrails Full Stack Launcher
REM Starts both the Hygiene Service and Flutter app

echo ==========================================
echo   TinyTrails Full Stack Launcher
echo ==========================================
echo.

REM Start Hygiene Service in background
echo [1/2] Starting Hygiene Service...
start "TinyTrails Hygiene Service" cmd /c "cd /d T:\College\Project\TinyTrail\hygiene_service && python app_unified.py"

REM Wait for service to initialize
echo [INFO] Waiting for service to start...
timeout /t 3 /nobreak >nul

REM Check if service is running
curl -s http://localhost:8000/health >nul 2>&1
if errorlevel 1 (
    echo [WARNING] Service may not be ready yet, continuing anyway...
) else (
    echo [INFO] Hygiene Service is running!
)

echo.
echo [2/2] Starting Flutter app...
cd /d "T:\College\Project\TinyTrail\tinytrails_mvp"
flutter run

echo.
echo [INFO] Flutter app closed. Hygiene service may still be running.
echo [INFO] Close the "TinyTrails Hygiene Service" window to stop it.
pause
