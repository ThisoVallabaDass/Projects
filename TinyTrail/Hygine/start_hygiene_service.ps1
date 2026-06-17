$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$python = Join-Path $root ".venv\Scripts\python.exe"
$overnightModel = Join-Path $root "models\hygiene_model_overnight.pth"
$defaultModel = Join-Path $root "models\hygiene_model.pth"

if (Test-Path $overnightModel) {
    $env:HYGIENE_MODEL_PATH = $overnightModel
}
elseif (-not $env:HYGIENE_MODEL_PATH -and (Test-Path $defaultModel)) {
    $env:HYGIENE_MODEL_PATH = $defaultModel
}

Write-Host "Starting TinyTrail hygiene API on http://localhost:8000"
Write-Host "Using model: $env:HYGIENE_MODEL_PATH"
Set-Location $root
& $python -m uvicorn app:app --host 0.0.0.0 --port 8000
