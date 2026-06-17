# TinyTrails Hygiene Service Startup Script (v3)
# Runs the FastAPI hygiene verification service

Write-Host "=============================================="
Write-Host "TinyTrails - Hygiene Service v3.1"
Write-Host "=============================================="
Write-Host ""

# Set working directory
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $scriptDir

# Check Python environment
if (Test-Path ".venv\Scripts\python.exe") {
    $python = ".venv\Scripts\python.exe"
    Write-Host "[OK] Using virtual environment" -ForegroundColor Green
} else {
    $python = "python"
    Write-Host "[WARNING] Using system Python" -ForegroundColor Yellow
}

# Check if model exists
$modelPath = "models\hygiene_model.pth"
if (Test-Path $modelPath) {
    $modelSize = [math]::Round((Get-Item $modelPath).Length / 1MB, 2)
    Write-Host "[OK] Model found ($modelSize MB)" -ForegroundColor Green
} else {
    Write-Host "[WARNING] Model not found - will use mock responses" -ForegroundColor Yellow
    Write-Host "Run .\train_model.ps1 to train the model"
}

# Create vendor baselines directory
if (-not (Test-Path "vendor_baselines")) {
    New-Item -ItemType Directory -Path "vendor_baselines" | Out-Null
    Write-Host "[OK] Created vendor_baselines directory" -ForegroundColor Green
}

# Check for new inference module
if (Test-Path "workspace_inference_v2.py") {
    Write-Host "[OK] Using v2 inference (detailed issue detection)" -ForegroundColor Green
} else {
    Write-Host "[INFO] Using legacy inference module" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Starting service on http://0.0.0.0:8000" -ForegroundColor Cyan
Write-Host "Press Ctrl+C to stop"
Write-Host ""
Write-Host "API Endpoints:"
Write-Host "  GET  /health              - Service health check"
Write-Host "  POST /verify-hygiene      - Single image verification"
Write-Host "  POST /train-baseline      - Train vendor baseline (5+ images)"
Write-Host "  POST /verify-daily        - Daily shift verification"
Write-Host "  GET  /vendors/{id}/status - Check vendor baseline status"
Write-Host "  GET  /issue-categories    - List all issue types"
Write-Host ""

# Set environment variables
$env:HYGIENE_MODEL_PATH = $modelPath
$env:BASELINE_IMAGES_DIR = "vendor_baselines"

# Run the service (try v3 first, fallback to original)
if (Test-Path "app_v3.py") {
    & $python -m uvicorn app_v3:app --host 0.0.0.0 --port 8000 --reload
} else {
    & $python -m uvicorn app:app --host 0.0.0.0 --port 8000 --reload
}
