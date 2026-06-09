#!/usr/bin/env pwsh
# Get-AzureSchema.ps1 - Query Azure resource type schemas from the command line.
#
# Data source: bicep-types-az (https://github.com/Azure/bicep-types-az)
#   - index.json for resource type discovery and API version listing
#   - types.json per resource type for schema definitions
#
# Output: JSON on stdout. Progress / errors on stderr.
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

    [int]$Depth = 5
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$script:PROG = 'Get-AzureSchema.ps1'
$script:CACHE_DIR = if ($env:XDG_CACHE_HOME) { Join-Path $env:XDG_CACHE_HOME 'azure-schema' } else { Join-Path $HOME '.cache' 'azure-schema' }
$script:BICEP_TYPES_BASE = 'https://raw.githubusercontent.com/Azure/bicep-types-az/main/generated'
$script:INDEX_URL = "$script:BICEP_TYPES_BASE/index.json"
$script:INDEX_CACHE = Join-Path $script:CACHE_DIR 'index.json'
$script:INDEX_MAX_AGE = [TimeSpan]::FromHours(24)

# Bicep type flags (bitfield): 1=Required, 2=ReadOnly, 4=WriteOnly, 8=DeployTimeConstant
$script:FLAG_REQUIRED = 1
$script:FLAG_READONLY = 2
$script:FLAG_WRITEONLY = 4

function Show-Usage {
    @"
Usage:
  $script:PROG get <ResourceType> <ApiVersion> [-Depth N]
  $script:PROG versions <ResourceProvider>
  $script:PROG help

Commands:
  get       Fetch the schema for a resource type at a given API version and emit
            resolved JSON on stdout. -Depth N caps nested object resolution
            (default 5).

  versions  List '<ResourceType>@<ApiVersion>' entries for all types under a
            provider, one per line on stdout.

Examples:
  $script:PROG get Microsoft.ContainerService/managedClusters 2025-10-01
  $script:PROG get Microsoft.Storage/storageAccounts 2023-01-01 -Depth 3
  $script:PROG versions Microsoft.Storage
"@
}

function Ensure-CacheDir {
    if (-not (Test-Path $script:CACHE_DIR)) {
        New-Item -ItemType Directory -Path $script:CACHE_DIR -Force | Out-Null
    }
}

function Fetch-Index {
    Ensure-CacheDir
    $needsFetch = -not (Test-Path $script:INDEX_CACHE)
    if (-not $needsFetch) {
        $age = (Get-Date) - (Get-Item $script:INDEX_CACHE).LastWriteTime
        $needsFetch = $age -gt $script:INDEX_MAX_AGE
    }
    if ($needsFetch) {
        [Console]::Error.WriteLine('Fetching resource type index (cached for 24h)...')
        Invoke-WebRequest -Uri $script:INDEX_URL -OutFile $script:INDEX_CACHE -UseBasicParsing | Out-Null
    }
}

$script:IndexData = $null
function Get-IndexData {
    if ($null -eq $script:IndexData) {
        $script:IndexData = Get-Content $script:INDEX_CACHE -Raw | ConvertFrom-Json
    }
    return $script:IndexData
}

function Resolve-IndexRef {
    param([string]$ResourceType, [string]$ApiVersion)

    $index = Get-IndexData
    $lookupKey = "$ResourceType@$ApiVersion"

    $prop = $index.resources.PSObject.Properties | Where-Object { $_.Name -eq $lookupKey } | Select-Object -First 1
    if (-not $prop) {
        $prop = $index.resources.PSObject.Properties | Where-Object { $_.Name -ieq $lookupKey } | Select-Object -First 1
    }
    if (-not $prop) { return $null }

    $ref = $prop.Value.PSObject.Properties['$ref'].Value
    if (-not $ref) { return $null }

    # ref format: "containerservice_0/microsoft.containerservice/2025-10-01/types.json#/376"
    $parts = $ref -split '#'
    return @{
        FilePath  = $parts[0]
        TypeIndex = [int]($parts[1].TrimStart('/'))
    }
}

function Fetch-TypesFile {
    param([string]$FilePath)

    Ensure-CacheDir
    $cacheKey = $FilePath -replace '[/\\]', '_'
    $cacheFile = Join-Path $script:CACHE_DIR $cacheKey

    if (-not (Test-Path $cacheFile)) {
        $url = "$script:BICEP_TYPES_BASE/$FilePath"
        [Console]::Error.WriteLine("Fetching types from $FilePath...")
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

# Strict-mode-safe property accessor. Returns the property value or $null
# if the property does not exist on the object.
function Get-Prop {
    param($Object, [string]$Name)
    if ($null -eq $Object) { return $null }
    $p = $Object.PSObject.Properties[$Name]
    if ($null -eq $p) { return $null }
    return $p.Value
}

function Resolve-TypeToJson {
    param($TypeDef, $Types, [int]$CurrentDepth, [int]$MaxDepth)

    if ($CurrentDepth -gt $MaxDepth) {
        return [ordered]@{ type = ((Get-Prop $TypeDef '$type') ?? 'unknown'); _truncated = 'depth limit exceeded' }
    }

    switch ((Get-Prop $TypeDef '$type')) {
        'StringType' {
            $result = [ordered]@{ type = 'string' }
            $minLength = Get-Prop $TypeDef 'minLength'
            $maxLength = Get-Prop $TypeDef 'maxLength'
            $pattern   = Get-Prop $TypeDef 'pattern'
            if ($null -ne $minLength) { $result.minLength = $minLength }
            if ($null -ne $maxLength) { $result.maxLength = $maxLength }
            if ($null -ne $pattern)   { $result.pattern   = $pattern }
            return $result
        }
        'StringLiteralType' { return [ordered]@{ type = 'string'; const = (Get-Prop $TypeDef 'value') } }
        'IntegerType' {
            $result = [ordered]@{ type = 'integer' }
            $minValue = Get-Prop $TypeDef 'minValue'
            $maxValue = Get-Prop $TypeDef 'maxValue'
            if ($null -ne $minValue) { $result.minimum = $minValue }
            if ($null -ne $maxValue) { $result.maximum = $maxValue }
            return $result
        }
        'BooleanType' { return [ordered]@{ type = 'boolean' } }
        'AnyType' { return [ordered]@{ type = 'any' } }
        'ArrayType' {
            $result = [ordered]@{ type = 'array' }
            $itemType = Get-Prop $TypeDef 'itemType'
            $itemRef  = Get-Prop $itemType '$ref'
            if ($itemRef) {
                $refIdx = [int]($itemRef -split '/' | Select-Object -Last 1)
                $result.items = Resolve-TypeToJson -TypeDef $Types[$refIdx] -Types $Types -CurrentDepth ($CurrentDepth + 1) -MaxDepth $MaxDepth
            }
            return $result
        }
        'UnionType' {
            $oneOf = @()
            $elements = (Get-Prop $TypeDef 'elements') ?? @()
            foreach ($elem in $elements) {
                $elemRef = Get-Prop $elem '$ref'
                if ($elemRef) {
                    $refIdx = [int]($elemRef -split '/' | Select-Object -Last 1)
                    $oneOf += , (Resolve-TypeToJson -TypeDef $Types[$refIdx] -Types $Types -CurrentDepth ($CurrentDepth + 1) -MaxDepth $MaxDepth)
                }
                else {
                    $oneOf += , $elem
                }
            }
            return [ordered]@{ type = 'union'; oneOf = $oneOf }
        }
        'ObjectType' {
            $result = [ordered]@{ type = 'object'; name = (Get-Prop $TypeDef 'name') }
            $properties = Get-Prop $TypeDef 'properties'
            if ($properties) {
                $props = [ordered]@{}
                foreach ($propEntry in $properties.PSObject.Properties) {
                    $propVal = $propEntry.Value
                    $propResult = [ordered]@{}

                    $propType = Get-Prop $propVal 'type'
                    $propRef  = Get-Prop $propType '$ref'
                    if ($propRef) {
                        $refIdx = [int]($propRef -split '/' | Select-Object -Last 1)
                        $resolved = Resolve-TypeToJson -TypeDef $Types[$refIdx] -Types $Types -CurrentDepth ($CurrentDepth + 1) -MaxDepth $MaxDepth
                        foreach ($k in $resolved.Keys) { $propResult[$k] = $resolved[$k] }
                    }

                    $description = Get-Prop $propVal 'description'
                    if ($description) { $propResult.description = $description }

                    $flags = [int]((Get-Prop $propVal 'flags') ?? 0)
                    if (($flags -band $script:FLAG_REQUIRED)  -ne 0) { $propResult.required  = $true }
                    if (($flags -band $script:FLAG_READONLY)  -ne 0) { $propResult.readOnly  = $true }
                    if (($flags -band $script:FLAG_WRITEONLY) -ne 0) { $propResult.writeOnly = $true }

                    $props[$propEntry.Name] = $propResult
                }
                $result.properties = $props
            }
            return $result
        }
        default { return [ordered]@{ type = ((Get-Prop $TypeDef '$type') ?? 'unknown') } }
    }
}

function Invoke-Versions {
    param([string]$Provider)

    if (-not $Provider) {
        throw "Usage: $script:PROG versions <ResourceProvider>  Example: $script:PROG versions Microsoft.Storage"
    }

    Fetch-Index
    $index = Get-IndexData
    $pattern = $Provider.ToLower()

    $entries = foreach ($prop in $index.resources.PSObject.Properties) {
        if ($prop.Name.ToLower().StartsWith($pattern)) { $prop.Name }
    }

    $entries | Sort-Object | ForEach-Object { Write-Output $_ }
}

function Invoke-Get {
    param([string]$ResourceType, [string]$ApiVersion, [int]$MaxDepth)

    if (-not $ResourceType -or -not $ApiVersion) {
        throw "Usage: $script:PROG get <ResourceType> <ApiVersion> [-Depth N]"
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
    $bodyRef = Get-Prop (Get-Prop $rt 'body') '$ref'
    if (-not $bodyRef) {
        throw "Resource type '$ResourceType@$ApiVersion' has no resolvable body reference in the types file."
    }
    $bodyRefIdx = [int]($bodyRef -split '/' | Select-Object -Last 1)
    $body = $types[$bodyRefIdx]

    $resolved = Resolve-TypeToJson -TypeDef $body -Types $types -CurrentDepth 0 -MaxDepth $MaxDepth
    $resolved | ConvertTo-Json -Depth 100
}

switch ($Command) {
    'get' { Invoke-Get -ResourceType $ResourceType -ApiVersion $ApiVersion -MaxDepth $Depth }
    'versions' { Invoke-Versions -Provider $ResourceType }
    'help' { Show-Usage }
    default { Show-Usage }
}
