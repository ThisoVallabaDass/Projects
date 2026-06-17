$env:PYTHONUTF8 = '1'
[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new()
$OutputEncoding = [Console]::OutputEncoding

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$python = Join-Path $root ".venv\Scripts\python.exe"
$logPath = Join-Path $root "overnight_pipeline.log"

Write-Host "TinyTrail overnight hygiene training"
Write-Host "Root : $root"
Write-Host "Log  : $logPath"

& $python (Join-Path $root "auto_pipeline.py") 2>&1 | Tee-Object -FilePath $logPath
