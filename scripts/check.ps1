param(
  [int]$MinCoverage = 80
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

Write-Host "==> flutter pub get"
flutter pub get

Write-Host "==> dart format"
dart format --set-exit-if-changed lib test

Write-Host "==> flutter analyze"
flutter analyze

Write-Host "==> flutter test --coverage"
flutter test --coverage

Write-Host "==> coverage gate"
& "$PSScriptRoot\coverage_gate.ps1" -MinCoverage $MinCoverage
