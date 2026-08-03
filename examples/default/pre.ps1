#!/usr/bin/env pwsh
# Sets up the environment for the default example.

Set-StrictMode -Version 3.0
$ErrorActionPreference = 'Stop'

$randomPrefix = Get-Random -Minimum 0 -Maximum 32768
$libDir = Join-Path $PSScriptRoot 'lib'

if (Test-Path -LiteralPath $libDir -PathType Container) {
    Push-Location -LiteralPath $libDir
    try {
        terraform init
        if ($LASTEXITCODE -ne 0) { throw "terraform init failed with exit code $LASTEXITCODE." }

        terraform apply -auto-approve "-var=prefix=$randomPrefix"
        if ($LASTEXITCODE -ne 0) { throw "terraform apply failed with exit code $LASTEXITCODE." }
    }
    finally {
        Pop-Location
    }
}
