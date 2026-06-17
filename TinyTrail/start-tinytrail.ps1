$projectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$backendDir = Join-Path $projectRoot 'model\backend-simple'
$mobileDir = Join-Path $projectRoot 'model\mobile'
$pythonBin = Join-Path $projectRoot 'Hygine\.venv\Scripts\python.exe'

function Get-LanIp {
    $preferredConfig = Get-NetIPConfiguration -ErrorAction SilentlyContinue |
        Where-Object {
            $_.IPv4Address -and
            $_.IPv4DefaultGateway -and
            $_.NetAdapter.Status -eq 'Up' -and
            $_.InterfaceAlias -notmatch 'Loopback|Bluetooth|vEthernet|VirtualBox|WSL'
        } |
        Select-Object -First 1

    if ($preferredConfig -and $preferredConfig.IPv4Address.IPAddress) {
        return $preferredConfig.IPv4Address.IPAddress
    }

    $fallback = ipconfig | Select-String 'IPv4 Address'
    foreach ($line in $fallback) {
        $candidate = ($line.ToString().Split(':')[-1]).Trim()
        if ($candidate -match '^(10\.|172\.(1[6-9]|2[0-9]|3[0-1])\.|192\.168\.)') {
            return $candidate
        }
    }

    return $null
}

$apiIp = Get-LanIp

if (-not $apiIp) {
    Write-Host ''
    Write-Host 'Could not detect your laptop LAN IP address.' -ForegroundColor Red
    Write-Host 'Run ipconfig and connect your phone and laptop to the same Wi-Fi, then try again.'
    exit 1
}

$apiUrl = "http://$apiIp`:8080/api"
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
    Write-Host "Expected command: cd $backendDir"
    Write-Host "`$env:PYTHON_BIN='$pythonBin'"
    Write-Host 'node server-v2.js'
    exit 1
}

Start-Process powershell -ArgumentList @(
    '-NoExit',
    '-Command',
    "Set-Location '$mobileDir'; `$env:EXPO_PUBLIC_API_URL='$apiUrl'; npx expo start --lan -c"
)

Write-Host ''
Write-Host 'TinyTrail is starting...' -ForegroundColor Green
Write-Host "Backend: $backendDir"
Write-Host "Mobile:  $mobileDir"
Write-Host "API URL: $apiUrl"
Write-Host ''
Write-Host 'If the backend was already running, only Expo was started.' -ForegroundColor Yellow
