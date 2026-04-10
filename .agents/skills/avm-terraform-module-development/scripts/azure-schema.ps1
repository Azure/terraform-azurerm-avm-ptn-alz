#!/usr/bin/env pwsh
# azure-schema.ps1 - Query Azure resource type schemas from the command line.
#
# Data source: bicep-types-az (https://github.com/Azure/bicep-types-az)
#   - index.json for resource type discovery and API version listing
#   - types.json per resource type for schema definitions
#
# Dependencies: PowerShell 7+

[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [ValidateSet('get', 'versions', 'help')]
    [string]$Command = 'help',

    [Parameter(Position = 1)]
    [string]$ResourceType,

    [Parameter(Position = 2)]
    [string]$ApiVersion,

    [switch]$Json,

    [int]$Depth = 5
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$script:PROG = 'azure-schema.ps1'
$script:CACHE_DIR = if ($env:XDG_CACHE_HOME) { Join-Path $env:XDG_CACHE_HOME 'azure-schema' } else { Join-Path $HOME '.cache' 'azure-schema' }
$script:BICEP_TYPES_BASE = 'https://raw.githubusercontent.com/Azure/bicep-types-az/main/generated'
$script:INDEX_URL = "$script:BICEP_TYPES_BASE/index.json"
$script:INDEX_CACHE = Join-Path $script:CACHE_DIR 'index.json'
$script:INDEX_MAX_AGE = [TimeSpan]::FromHours(24)

# Bicep type flags (bitfield)
# 1 = Required, 2 = ReadOnly, 4 = WriteOnly, 8 = DeployTimeConstant
$script:FLAG_REQUIRED = 1
$script:FLAG_READONLY = 2
$script:FLAG_WRITEONLY = 4

# --------------------------------------------------------------------------- #
# Helpers
# --------------------------------------------------------------------------- #

function Show-Usage {
    @"
Usage:
  $script:PROG get <ResourceType> <ApiVersion> [-Json] [-Depth N]
  $script:PROG versions <ResourceProvider>
  $script:PROG help

Commands:
  get       Fetch the schema for a resource type at a given API version.
            Default output is a human-readable summary. Pass -Json for raw resolved JSON.
            -Depth N  Resolve nested object properties to N levels deep (default: 5).

  versions  List available API versions for all resource types under a provider.

Examples:
  $script:PROG get Microsoft.ContainerService/managedClusters 2025-10-01
  $script:PROG get Microsoft.Storage/storageAccounts 2023-01-01 -Json
  $script:PROG get Microsoft.Storage/storageAccounts 2023-01-01 -Depth 3
  $script:PROG versions Microsoft.Storage
"@
}

function Ensure-CacheDir {
    if (-not (Test-Path $script:CACHE_DIR)) {
        New-Item -ItemType Directory -Path $script:CACHE_DIR -Force | Out-Null
    }
}

# --------------------------------------------------------------------------- #
# Index management
# --------------------------------------------------------------------------- #

function Fetch-Index {
    Ensure-CacheDir
    $needsFetch = $false

    if (-not (Test-Path $script:INDEX_CACHE)) {
        $needsFetch = $true
    }
    else {
        $age = (Get-Date) - (Get-Item $script:INDEX_CACHE).LastWriteTime
        if ($age -gt $script:INDEX_MAX_AGE) {
            $needsFetch = $true
        }
    }

    if ($needsFetch) {
        Write-Host 'Fetching resource type index (cached for 24h)...' -ForegroundColor DarkGray
        try {
            Invoke-WebRequest -Uri $script:INDEX_URL -OutFile $script:INDEX_CACHE -UseBasicParsing | Out-Null
        }
        catch {
            throw "Failed to download index from $script:INDEX_URL : $_"
        }
    }
}

$script:IndexData = $null

function Get-IndexData {
    if ($null -eq $script:IndexData) {
        $script:IndexData = Get-Content $script:INDEX_CACHE -Raw | ConvertFrom-Json
    }
    return $script:IndexData
}

# Look up a resource type in the index and return file_path and type_index.
function Resolve-IndexRef {
    param(
        [string]$ResourceType,
        [string]$ApiVersion
    )

    $index = Get-IndexData
    $lookupKey = "$ResourceType@$ApiVersion"

    # Try exact match first, then case-insensitive
    $ref = $null
    $resources = $index.resources
    $prop = $resources.PSObject.Properties | Where-Object { $_.Name -eq $lookupKey } | Select-Object -First 1
    if (-not $prop) {
        $prop = $resources.PSObject.Properties | Where-Object { $_.Name -ieq $lookupKey } | Select-Object -First 1
    }

    if (-not $prop) {
        return $null
    }

    $ref = $prop.Value.'$ref'
    if (-not $ref) {
        return $null
    }

    # ref format: "containerservice_0/microsoft.containerservice/2025-10-01/types.json#/376"
    $parts = $ref -split '#'
    $filePath = $parts[0]
    $typeIndex = [int]($parts[1].TrimStart('/'))

    return @{
        FilePath  = $filePath
        TypeIndex = $typeIndex
    }
}

# --------------------------------------------------------------------------- #
# Types file management
# --------------------------------------------------------------------------- #

function Fetch-TypesFile {
    param([string]$FilePath)

    Ensure-CacheDir
    $cacheKey = $FilePath -replace '[/\\]', '_'
    $cacheFile = Join-Path $script:CACHE_DIR $cacheKey

    if (-not (Test-Path $cacheFile)) {
        $url = "$script:BICEP_TYPES_BASE/$FilePath"
        Write-Host "Fetching types from $FilePath..." -ForegroundColor DarkGray
        try {
            Invoke-WebRequest -Uri $url -OutFile $cacheFile -UseBasicParsing | Out-Null
        }
        catch {
            if (Test-Path $cacheFile) { Remove-Item $cacheFile -Force }
            throw "Failed to fetch $url : $_"
        }
    }

    return $cacheFile
}

function Get-TypesData {
    param([string]$CacheFile)
    return Get-Content $CacheFile -Raw | ConvertFrom-Json
}

# --------------------------------------------------------------------------- #
# Type resolution helpers
# --------------------------------------------------------------------------- #

function Get-TypeStr {
    param($TypeDef, $Types)

    switch ($TypeDef.'$type') {
        'StringType' { return 'string' }
        'StringLiteralType' { return "`"$($TypeDef.value)`"" }
        'IntegerType' { return 'integer' }
        'BooleanType' { return 'boolean' }
        'AnyType' { return 'any' }
        'ArrayType' {
            if ($TypeDef.itemType -and $TypeDef.itemType.'$ref') {
                $refIdx = [int]($TypeDef.itemType.'$ref' -split '/' | Select-Object -Last 1)
                $itemStr = Get-TypeStr -TypeDef $Types[$refIdx] -Types $Types
                return "array<$itemStr>"
            }
            return 'array'
        }
        'UnionType' {
            $parts = @()
            foreach ($elem in $TypeDef.elements) {
                if ($elem.'$ref') {
                    $refIdx = [int]($elem.'$ref' -split '/' | Select-Object -Last 1)
                    $parts += Get-TypeStr -TypeDef $Types[$refIdx] -Types $Types
                }
                else {
                    $parts += '?'
                }
            }
            return '(' + ($parts -join ' | ') + ')'
        }
        'ObjectType' { return if ($TypeDef.name) { $TypeDef.name } else { 'object' } }
        'ResourceType' { return if ($TypeDef.name) { $TypeDef.name } else { 'resource' } }
        default { return $TypeDef.'$type' ?? 'unknown' }
    }
}

function Resolve-TypeToJson {
    param($TypeDef, $Types, [int]$CurrentDepth, [int]$MaxDepth)

    if ($CurrentDepth -gt $MaxDepth) {
        if ($TypeDef.'$type' -eq 'ObjectType') {
            return [ordered]@{ type = 'object'; name = $TypeDef.name; _truncated = 'depth limit exceeded' }
        }
        return [ordered]@{ type = ($TypeDef.'$type' ?? 'unknown'); _truncated = 'depth limit exceeded' }
    }

    switch ($TypeDef.'$type') {
        'StringType' {
            $result = [ordered]@{ type = 'string' }
            if ($null -ne $TypeDef.minLength) { $result.minLength = $TypeDef.minLength }
            if ($null -ne $TypeDef.maxLength) { $result.maxLength = $TypeDef.maxLength }
            if ($null -ne $TypeDef.pattern) { $result.pattern = $TypeDef.pattern }
            return $result
        }
        'StringLiteralType' {
            return [ordered]@{ type = 'string'; const = $TypeDef.value }
        }
        'IntegerType' {
            $result = [ordered]@{ type = 'integer' }
            if ($null -ne $TypeDef.minValue) { $result.minimum = $TypeDef.minValue }
            if ($null -ne $TypeDef.maxValue) { $result.maximum = $TypeDef.maxValue }
            return $result
        }
        'BooleanType' { return [ordered]@{ type = 'boolean' } }
        'AnyType' { return [ordered]@{ type = 'any' } }
        'ArrayType' {
            $result = [ordered]@{ type = 'array' }
            if ($TypeDef.itemType -and $TypeDef.itemType.'$ref') {
                $refIdx = [int]($TypeDef.itemType.'$ref' -split '/' | Select-Object -Last 1)
                $result.items = Resolve-TypeToJson -TypeDef $Types[$refIdx] -Types $Types -CurrentDepth ($CurrentDepth + 1) -MaxDepth $MaxDepth
            }
            return $result
        }
        'UnionType' {
            $oneOf = @()
            foreach ($elem in $TypeDef.elements) {
                if ($elem.'$ref') {
                    $refIdx = [int]($elem.'$ref' -split '/' | Select-Object -Last 1)
                    $oneOf += , (Resolve-TypeToJson -TypeDef $Types[$refIdx] -Types $Types -CurrentDepth ($CurrentDepth + 1) -MaxDepth $MaxDepth)
                }
                else {
                    $oneOf += , $elem
                }
            }
            return [ordered]@{ type = 'union'; oneOf = $oneOf }
        }
        'ObjectType' {
            $result = [ordered]@{ type = 'object'; name = $TypeDef.name }
            if ($TypeDef.properties) {
                $props = [ordered]@{}
                foreach ($propEntry in $TypeDef.properties.PSObject.Properties) {
                    $propName = $propEntry.Name
                    $propVal = $propEntry.Value
                    $propResult = [ordered]@{}

                    if ($propVal.type -and $propVal.type.'$ref') {
                        $refIdx = [int]($propVal.type.'$ref' -split '/' | Select-Object -Last 1)
                        $resolved = Resolve-TypeToJson -TypeDef $Types[$refIdx] -Types $Types -CurrentDepth ($CurrentDepth + 1) -MaxDepth $MaxDepth
                        foreach ($k in $resolved.Keys) { $propResult[$k] = $resolved[$k] }
                    }

                    if ($propVal.description) { $propResult.description = $propVal.description }

                    $flags = [int]($propVal.flags ?? 0)
                    if (($flags -band $script:FLAG_REQUIRED) -ne 0) { $propResult.required = $true }
                    if (($flags -band $script:FLAG_READONLY) -ne 0) { $propResult.readOnly = $true }
                    if (($flags -band $script:FLAG_WRITEONLY) -ne 0) { $propResult.writeOnly = $true }

                    $props[$propName] = $propResult
                }
                $result.properties = $props
            }
            return $result
        }
        default {
            return [ordered]@{ type = ($TypeDef.'$type' ?? 'unknown') }
        }
    }
}

# --------------------------------------------------------------------------- #
# cmd: versions
# --------------------------------------------------------------------------- #

function Invoke-Versions {
    param([string]$Provider)

    if (-not $Provider) {
        throw "Usage: $script:PROG versions <ResourceProvider>  Example: $script:PROG versions Microsoft.Storage"
    }

    Fetch-Index
    $index = Get-IndexData
    $pattern = $Provider.ToLower()

    $entries = @()
    foreach ($prop in $index.resources.PSObject.Properties) {
        if ($prop.Name.ToLower().StartsWith($pattern)) {
            $parts = $prop.Name -split '@'
            $entries += [PSCustomObject]@{
                ResourceType = $parts[0]
                ApiVersion   = $parts[1]
            }
        }
    }

    $entries | Sort-Object ResourceType, ApiVersion | Format-Table -AutoSize -HideTableHeaders

    Write-Host ''
    Write-Host "$($entries.Count) resource type/version(s) found for $Provider" -ForegroundColor DarkGray
}

# --------------------------------------------------------------------------- #
# cmd: get
# --------------------------------------------------------------------------- #

function Invoke-Get {
    param(
        [string]$ResourceType,
        [string]$ApiVersion,
        [bool]$JsonOutput,
        [int]$MaxDepth
    )

    if (-not $ResourceType) {
        throw "Usage: $script:PROG get <ResourceType> <ApiVersion> [-Json]"
    }
    if (-not $ApiVersion) {
        throw "Usage: $script:PROG get <ResourceType> <ApiVersion> [-Json]"
    }

    Fetch-Index

    $refInfo = Resolve-IndexRef -ResourceType $ResourceType -ApiVersion $ApiVersion
    if (-not $refInfo) {
        $provider = ($ResourceType -split '/')[0]
        throw "Resource type '$ResourceType@$ApiVersion' not found in index.`nUse '$script:PROG versions $provider' to list available versions."
    }

    $typesFile = Fetch-TypesFile -FilePath $refInfo.FilePath
    $types = Get-TypesData -CacheFile $typesFile

    $rt = $types[$refInfo.TypeIndex]
    $bodyRefIdx = [int]($rt.body.'$ref' -split '/' | Select-Object -Last 1)
    $body = $types[$bodyRefIdx]

    if ($JsonOutput) {
        $resolved = Resolve-TypeToJson -TypeDef $body -Types $types -CurrentDepth 0 -MaxDepth $MaxDepth
        $resolved | ConvertTo-Json -Depth 100
    }
    else {
        Render-Summary -Body $body -Types $types -ResourceType $ResourceType -ApiVersion $ApiVersion -MaxDepth $MaxDepth
    }
}

# --------------------------------------------------------------------------- #
# Human-readable summary renderer
# --------------------------------------------------------------------------- #

function Render-Summary {
    param($Body, $Types, [string]$ResourceType, [string]$ApiVersion, [int]$MaxDepth)

    $line = [string]::new([char]0x2501, 80)
    $thinLine = [string]::new([char]0x2500, 79)

    Write-Host $line
    Write-Host "  $ResourceType @ $ApiVersion"
    Write-Host $line
    Write-Host ''
    Write-Host 'PROPERTIES:'
    Write-Host $thinLine

    $requiredProps = @()

    function Print-Props {
        param($TypeDef, $Types, [string]$Indent, [int]$CurrentDepth, [int]$MaxDepth)

        if (-not $TypeDef.properties) { return }

        foreach ($propEntry in $TypeDef.properties.PSObject.Properties) {
            $propName = $propEntry.Name
            $propVal = $propEntry.Value
            $flags = [int]($propVal.flags ?? 0)

            # Resolve the type
            $resolved = $null
            if ($propVal.type -and $propVal.type.'$ref') {
                $refIdx = [int]($propVal.type.'$ref' -split '/' | Select-Object -Last 1)
                $resolved = $Types[$refIdx]
            }

            $tStr = if ($resolved) { Get-TypeStr -TypeDef $resolved -Types $Types } else { 'unknown' }

            $flagStr = ''
            if (($flags -band $script:FLAG_REQUIRED) -ne 0) {
                $flagStr += ' [REQUIRED]'
                if ($CurrentDepth -eq 0) { $script:requiredList += $propName }
            }
            if (($flags -band $script:FLAG_READONLY) -ne 0) { $flagStr += ' [READ-ONLY]' }
            if (($flags -band $script:FLAG_WRITEONLY) -ne 0) { $flagStr += ' [WRITE-ONLY]' }

            Write-Host "${Indent}  ${propName}: ${tStr}${flagStr}"

            if ($propVal.description) {
                $desc = $propVal.description
                if ($desc.Length -gt 120) { $desc = $desc.Substring(0, 120) + '...' }
                Write-Host "${Indent}      $desc"
            }

            # Recurse into nested ObjectType
            if ($resolved -and $resolved.'$type' -eq 'ObjectType' -and $resolved.properties) {
                if ($CurrentDepth -lt $MaxDepth) {
                    Print-Props -TypeDef $resolved -Types $Types -Indent "${Indent}    " -CurrentDepth ($CurrentDepth + 1) -MaxDepth $MaxDepth
                }
                else {
                    Write-Host "${Indent}      (...depth limit exceeded)"
                }
            }
        }
    }

    $script:requiredList = @()
    Print-Props -TypeDef $Body -Types $Types -Indent '' -CurrentDepth 0 -MaxDepth $MaxDepth

    Write-Host ''
    Write-Host $thinLine
    Write-Host "Required: $($script:requiredList -join ', ')"
    Write-Host ''
}

# --------------------------------------------------------------------------- #
# Main
# --------------------------------------------------------------------------- #

switch ($Command) {
    'get' {
        Invoke-Get -ResourceType $ResourceType -ApiVersion $ApiVersion -JsonOutput $Json.IsPresent -MaxDepth $Depth
    }
    'versions' {
        Invoke-Versions -Provider $ResourceType
    }
    'help' {
        Show-Usage
    }
    default {
        Show-Usage
    }
}
