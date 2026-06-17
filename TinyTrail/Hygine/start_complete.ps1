# TinyTrails Hygiene AI - Complete Setup
# This script trains the model and starts the service

Write-Host ""
Write-Host "=============================================="
Write-Host "  TinyTrails - Indian Kitchen Hygiene AI"
Write-Host "  Complete Setup & Startup"
Write-Host "=============================================="
Write-Host ""

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $scriptDir

# Check for Python environment
if (Test-Path ".venv\Scripts\python.exe") {
    $python = ".venv\Scripts\python.exe"
    Write-Host "[OK] Virtual environment found" -ForegroundColor Green
} elseif (Test-Path ".venv\Scripts\Activate.ps1") {
    & ".venv\Scripts\Activate.ps1"
    $python = "python"
    Write-Host "[OK] Virtual environment activated" -ForegroundColor Green
} else {
    Write-Host "[WARNING] No virtual environment found" -ForegroundColor Yellow
    Write-Host "Creating virtual environment..."
    python -m venv .venv
    & ".venv\Scripts\Activate.ps1"
    $python = ".venv\Scripts\python.exe"

    Write-Host "Installing dependencies..."
    & $python -m pip install --upgrade pip
    & $python -m pip install -r requirements.txt
}

# Check for existing trained model
$modelPath = "models\hygiene_model.pth"
$needsTraining = $true

if (Test-Path $modelPath) {
    $modelAge = (Get-Date) - (Get-Item $modelPath).LastWriteTime
    Write-Host ""
    Write-Host "[INFO] Existing model found (${modelAge.Days} days old)" -ForegroundColor Cyan

    $response = Read-Host "Do you want to retrain the model? (y/N)"
    if ($response.ToLower() -ne 'y') {
        $needsTraining = $false
    }
}

if ($needsTraining) {
    Write-Host ""
    Write-Host "Starting model training..." -ForegroundColor Cyan
    Write-Host "This may take 20-40 minutes..."
    Write-Host ""

    & $python train_indian_kitchen.py `
        --dataset-dir "AI_Hygiene_Model\dataset" `
        --output "models\hygiene_model_indian_kitchen.pth" `
        --epochs 50 `
        --batch-size 32 `
        --arch "efficientnet_b0" `
        --patience 12

    if ($LASTEXITCODE -ne 0) {
        Write-Host ""
        Write-Host "[ERROR] Training failed!" -ForegroundColor Red
        exit 1
    }

    Write-Host ""
    Write-Host "[OK] Training complete!" -ForegroundColor Green
}

# Start the service
Write-Host ""
Write-Host "=============================================="
Write-Host "Starting Hygiene Service..."
Write-Host "=============================================="
Write-Host ""
Write-Host "API will be available at: http://localhost:8000" -ForegroundColor Cyan
Write-Host "For Android emulator use: http://10.0.2.2:8000"
Write-Host ""
Write-Host "Press Ctrl+C to stop the service"
Write-Host ""

$env:HYGIENE_MODEL_PATH = "models\hygiene_model.pth"
$env:BASELINE_IMAGES_DIR = "vendor_baselines"

if (Test-Path "app_v3.py") {
    & $python -m uvicorn app_v3:app --host 0.0.0.0 --port 8000 --reload
} else {
    & $python -m uvicorn app:app --host 0.0.0.0 --port 8000 --reload
}
