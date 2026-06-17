$env:PYTHONUTF8 = '1'
[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new()
$OutputEncoding = [Console]::OutputEncoding
$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$python = Join-Path $root ".venv\Scripts\python.exe"
$logPath = Join-Path $root "overnight_pipeline.log"
$resumeLogPath = Join-Path $root "overnight_resume_utf8.log"
$modelPath = Join-Path $root "models\hygiene_model_overnight.pth"
$reportPath = Join-Path $root "models\training_report_overnight.json"

function Write-Section([string]$title) {
    $line = "=" * 84
    Write-Host ""
    Write-Host $line
    Write-Host $title
    Write-Host $line
}

function Invoke-Step([string]$title, [string[]]$command) {
    Write-Section $title
    Write-Host ($command -join " ")
    & $command[0] $command[1..($command.Length - 1)]
    if ($LASTEXITCODE -ne 0) {
        throw "Step failed: $title"
    }
}

Write-Section "TINYTRAIL OVERNIGHT HYGIENE PIPELINE (RESUME)"
Write-Host "Working directory : $root"
Write-Host "Python            : $python"
Write-Host "Resume log        : $resumeLogPath"
Write-Host "Model output      : $modelPath"
Write-Host "Report output     : $reportPath"

Push-Location $root
try {
    Start-Transcript -Path $resumeLogPath -Append | Out-Null
    Invoke-Step "STEP 2: REMOVE EXACT DUPLICATES" @(
        $python,
        "deduplicate_dataset.py",
        "--exact-only"
    )

    Invoke-Step "STEP 3: CLEAN LOW-QUALITY / IRRELEVANT IMAGES" @(
        $python,
        "clean_dataset.py",
        "--filter-irrelevant",
        "--min-size",
        "224"
    )

    Invoke-Step "STEP 4: TRAIN THE UPDATED MODEL" @(
        $python,
        "train_enhanced.py",
        "--epochs",
        "35",
        "--batch-size",
        "16",
        "--arch",
        "efficientnet_b0",
        "--lr",
        "0.0003",
        "--freeze-epochs",
        "4",
        "--output",
        $modelPath,
        "--report-path",
        $reportPath
    )

    Invoke-Step "STEP 5: EVALUATE THE FINAL CHECKPOINT" @(
        $python,
        "evaluate.py",
        "--model-path",
        $modelPath,
        "--batch-size",
        "16"
    )

    Write-Section "OVERNIGHT PIPELINE COMPLETE"
    Write-Host "Model  : $modelPath"
    Write-Host "Report : $reportPath"
}
finally {
    Stop-Transcript | Out-Null
    Pop-Location
}
