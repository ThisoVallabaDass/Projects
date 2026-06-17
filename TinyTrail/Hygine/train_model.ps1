# TinyTrails Hygiene Model Training Script
# This script trains the AI model for Indian kitchen hygiene detection

Write-Host "=============================================="
Write-Host "TinyTrails - Indian Kitchen Hygiene AI Training"
Write-Host "=============================================="
Write-Host ""

# Set working directory
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $scriptDir

# Check if Python virtual environment exists
if (Test-Path ".venv\Scripts\python.exe") {
    $python = ".venv\Scripts\python.exe"
    Write-Host "[OK] Found Python virtual environment" -ForegroundColor Green
} else {
    $python = "python"
    Write-Host "[WARNING] Using system Python" -ForegroundColor Yellow
}

# Check if dataset exists
$datasetPath = "AI_Hygiene_Model\dataset"
if (Test-Path $datasetPath) {
    $classCount = (Get-ChildItem $datasetPath -Directory | Where-Object { -not $_.Name.StartsWith('_') }).Count
    Write-Host "[OK] Dataset found with $classCount classes" -ForegroundColor Green
} else {
    Write-Host "[ERROR] Dataset not found at $datasetPath" -ForegroundColor Red
    exit 1
}

# Count images
$totalImages = 0
Get-ChildItem "$datasetPath\*" -Directory | Where-Object { -not $_.Name.StartsWith('_') } | ForEach-Object {
    $className = $_.Name
    $count = (Get-ChildItem $_.FullName -Include @("*.jpg", "*.jpeg", "*.png") -Recurse).Count
    Write-Host "  - $className : $count images"
    $totalImages += $count
}
Write-Host "  Total: $totalImages images"
Write-Host ""

# Create models directory if needed
if (-not (Test-Path "models")) {
    New-Item -ItemType Directory -Path "models" | Out-Null
    Write-Host "[OK] Created models directory" -ForegroundColor Green
}

# Start training
Write-Host ""
Write-Host "Starting training..." -ForegroundColor Cyan
Write-Host "This may take 20-40 minutes depending on your hardware."
Write-Host ""

$trainArgs = @(
    "train_indian_kitchen.py",
    "--dataset-dir", $datasetPath,
    "--output", "models\hygiene_model_indian_kitchen.pth",
    "--epochs", "50",
    "--batch-size", "32",
    "--arch", "efficientnet_b0",
    "--patience", "12"
)

# Run training
& $python $trainArgs

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "=============================================="
    Write-Host "Training Complete!" -ForegroundColor Green
    Write-Host "=============================================="
    Write-Host "Model saved to: models\hygiene_model_indian_kitchen.pth"
    Write-Host "Also saved as: models\hygiene_model.pth (for API)"
    Write-Host ""
    Write-Host "To start the hygiene service, run:"
    Write-Host "  .\start_hygiene_service_v3.ps1"
} else {
    Write-Host ""
    Write-Host "[ERROR] Training failed!" -ForegroundColor Red
    Write-Host "Check the logs for details."
}
