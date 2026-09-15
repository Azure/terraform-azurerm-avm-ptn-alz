#!/usr/bin/env pwsh
# Sets up the environment for the default example.

Set-StrictMode -Version 3.0
$ErrorActionPreference = 'Stop'

function Resolve-Terraform {
    $cmd = Get-Command terraform -CommandType Application -ErrorAction SilentlyContinue
    if ($cmd) {
        return $cmd.Source
    }

    if (-not [string]::IsNullOrWhiteSpace($env:AVM_HOME)) {
        $exeName = if ($IsWindows) { 'terraform.exe' } else { 'terraform' }
        $terraformRoot = Join-Path $env:AVM_HOME 'tools/terraform'

        if (Test-Path -LiteralPath $terraformRoot -PathType Container) {
            $candidate = Get-ChildItem -LiteralPath $terraformRoot -Directory -ErrorAction SilentlyContinue |
                Sort-Object -Property Name -Descending |
                ForEach-Object {
                    $path = Join-Path $_.FullName $exeName
                    if (Test-Path -LiteralPath $path -PathType Leaf) {
                        $path
                    }
                } |
                Select-Object -First 1

            if ($candidate) {
                return $candidate
            }
        }
    }

    throw "Terraform was not found on PATH or under AVM_HOME/tools/terraform."
}

$terraform = Resolve-Terraform

$randomPrefix = Get-Random -Minimum 0 -Maximum 32768
$libDir = Join-Path $PSScriptRoot 'lib'

if (Test-Path -LiteralPath $libDir -PathType Container) {
    Push-Location -LiteralPath $libDir
    try {
        & $terraform init
        if ($LASTEXITCODE -ne 0) { throw "terraform init failed with exit code $LASTEXITCODE." }

        & $terraform apply -auto-approve "-var=prefix=$randomPrefix"
        if ($LASTEXITCODE -ne 0) { throw "terraform apply failed with exit code $LASTEXITCODE." }
    }
    finally {
        Pop-Location
    }
}