# ThoughtForge - Run All
# Runs: review → check → apply

$ErrorActionPreference = "Stop"
$scriptDir = $PSScriptRoot

& "$scriptDir\review.ps1"
& "$scriptDir\check.ps1"
& "$scriptDir\apply.ps1"
