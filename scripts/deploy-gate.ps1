# Deploy gate: run before deploying the app.
# Verifies real production links have no regression (secret chat / E2EE / timed destroy / channels).
# Requires local Flutter SDK (PATH or FLUTTER_BIN).
#
# Usage:
#   powershell -ExecutionPolicy Bypass -File scripts/deploy-gate.ps1

$ErrorActionPreference = 'Stop'

$flutter = if ($env:FLUTTER_BIN) { $env:FLUTTER_BIN } else { 'flutter' }
$appRoot = Split-Path -Parent $PSScriptRoot

Write-Host '=== [1/3] flutter analyze ==='
Push-Location $appRoot
try {
  & $flutter analyze lib test integration_test packages/open_core/lib packages/open_ui/lib
  if ($LASTEXITCODE -ne 0) { throw 'flutter analyze failed' }
} finally { Pop-Location }

Write-Host '=== [2/3] unit + contract tests (exclude integration) ==='
Push-Location $appRoot
try {
  & $flutter test --exclude-tags integration
  if ($LASTEXITCODE -ne 0) { throw 'unit/contract tests failed' }
} finally { Pop-Location }

Write-Host '=== [3/3] integration regression (production links) ==='
Push-Location $appRoot
try {
  & $flutter test test/integration --tags integration --run-skipped
  if ($LASTEXITCODE -ne 0) { throw 'integration regression failed' }
} finally { Pop-Location }

Write-Host ''
Write-Host '== DEPLOY GATE PASSED. Ready to deploy. =='
