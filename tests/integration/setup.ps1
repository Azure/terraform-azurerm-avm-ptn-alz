#!/usr/bin/env pwsh

Set-StrictMode -Version 3.0
$ErrorActionPreference = 'Stop'

$sourceDirectory = Join-Path $PSScriptRoot 'testdata/multipleroledefs'
$generatedDirectory = Join-Path $PSScriptRoot 'testdata/generated/multipleroledefs'
$architectureFile = 'test.alz_architecture_definition.yml'

if (Test-Path -LiteralPath $generatedDirectory) {
    Remove-Item -LiteralPath $generatedDirectory -Recurse -Force
}

New-Item -ItemType Directory -Path $generatedDirectory -Force | Out-Null
Copy-Item -Path (Join-Path $sourceDirectory '*') -Destination $generatedDirectory -Recurse

$runId = if ($env:GITHUB_RUN_ID) {
    "$($env:GITHUB_RUN_ID)-$($env:GITHUB_RUN_ATTEMPT)"
}
else {
    [Guid]::NewGuid().ToString('N').Substring(0, 12)
}
$prefix = "avm-alz-$runId"
$architecturePath = Join-Path $generatedDirectory $architectureFile
$architecture = Get-Content -LiteralPath $architecturePath -Raw
$architecture = $architecture.Replace('test1', "$prefix-1").Replace('test2', "$prefix-2")
[System.IO.File]::WriteAllText($architecturePath, $architecture)
