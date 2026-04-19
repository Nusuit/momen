param(
  [int]$MinCoverage = 80,
  [string]$LcovPath = "coverage/lcov.info"
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

if (-not (Test-Path $LcovPath)) {
  Write-Error "Coverage file not found: $LcovPath. Run flutter test --coverage first."
}

$linesFound = 0
$linesHit = 0

foreach ($line in Get-Content $LcovPath) {
  if ($line.StartsWith("LF:")) {
    $linesFound += [int]$line.Substring(3)
  }

  if ($line.StartsWith("LH:")) {
    $linesHit += [int]$line.Substring(3)
  }
}

if ($linesFound -eq 0) {
  Write-Error "Coverage file contains no line data."
}

$coverage = [math]::Round(($linesHit / $linesFound) * 100, 2)
Write-Host "Coverage: $coverage% ($linesHit/$linesFound lines)"

if ($coverage -lt $MinCoverage) {
  Write-Error "Coverage $coverage% is below required threshold $MinCoverage%."
}
