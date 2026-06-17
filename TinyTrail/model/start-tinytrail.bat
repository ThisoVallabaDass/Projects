@echo off
echo Starting Tiny Trail Backend...
cd backend-simple
start "Backend Server" cmd /k "node server.js"

echo Starting Tiny Trail Mobile App...
cd ..\mobile
start "Mobile App" cmd /k "npx expo start"

echo Both services are starting...
echo Backend: http://localhost:8080
echo Mobile: Check the new window for QR code
pause

