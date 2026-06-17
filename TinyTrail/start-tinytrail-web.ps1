$projectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$backendDir = Join-Path $projectRoot 'model\backend-simple'
$pythonBin = Join-Path $projectRoot 'Hygine\.venv\Scripts\python.exe'
$webUrl = 'http://localhost:8080'

$backendRunning = Get-NetTCPConnection -LocalPort 8080 -State Listen -ErrorAction SilentlyContinue

if (-not $backendRunning) {
    Start-Process powershell -ArgumentList @(
        '-NoExit',
        '-Command',
        "Set-Location '$backendDir'; `$env:PYTHON_BIN='$pythonBin'; node server-v2.js"
    )

    $attempt = 0
    do {
        Start-Sleep -Seconds 1
        $attempt++
        $health = $null
        try {
            $health = Invoke-WebRequest "http://localhost:8080/api/health" -UseBasicParsing -TimeoutSec 2
        } catch {
            $health = $null
        }
    } while (-not $health -and $attempt -lt 12)
}

if (-not (Invoke-WebRequest "http://localhost:8080/api/health" -UseBasicParsing -TimeoutSec 2 -ErrorAction SilentlyContinue)) {
    Write-Host ''
    Write-Host 'Backend did not start correctly. Start the backend manually first.' -ForegroundColor Red
    exit 1
}

Start-Process powershell -ArgumentList @(
    '-Command',
    "Start-Process '$webUrl'"
)

Write-Host ''
Write-Host 'TinyTrail web is starting...' -ForegroundColor Green
Write-Host "Backend: $backendDir"
Write-Host "Web URL:  $webUrl"
Write-Host ''
Write-Host 'Open the browser window for the new TinyTrail web app.' -ForegroundColor Yellow
