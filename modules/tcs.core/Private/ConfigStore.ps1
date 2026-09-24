<#
.SYNOPSIS
    Internal helpers for reading and writing tcs module configuration files.

.NOTES
    Private helpers for the tcs.core module.
#>

# Per-session cache of resolved module configuration, keyed by module name.
# Populated by Get-ModuleConfig / Set-ModuleConfig and read by Invoke-TelemetryCollection.
$script:ModuleConfigCache = @{}

function Read-JsonFileAsHashtable {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )

    $result = @{}
    $json = Get-Content -LiteralPath $Path -Raw -ErrorAction Stop
    if ([string]::IsNullOrWhiteSpace($json)) {
        return $result
    }
    $object = $json | ConvertFrom-Json -ErrorAction Stop
    foreach ($property in $object.PSObject.Properties) {
        $result[$property.Name] = $property.Value
    }
    return $result
}

function Write-JsonFile {
    [CmdletBinding()]
    [OutputType([void])]
    param(
        [Parameter(Mandatory)]
        [string]$Path,

        [Parameter(Mandatory)]
        [System.Collections.IDictionary]$Data
    )

    $directory = Split-Path -Path $Path -Parent
    if ($directory -and -not (Test-Path -LiteralPath $directory)) {
        $null = New-Item -Path $directory -ItemType Directory -Force -ErrorAction Stop
    }

    # Sort keys so the file is stable and readable
    $ordered = [ordered]@{}
    foreach ($key in ($Data.Keys | Sort-Object)) {
        $ordered[$key] = $Data[$key]
    }
    $ordered | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $Path -Encoding UTF8 -ErrorAction Stop
}

function Get-DefaultModuleConfig {
    <#
    .SYNOPSIS
        Returns the tcs.core defaults, overlaid with the calling module's own
        Config/Module.Defaults.json when one exists.
    #>
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [string]$ModulePath
    )

    $coreDefaultsPath = Join-Path -Path (Join-Path -Path $script:TcsCoreModuleRoot -ChildPath 'Config') -ChildPath 'Module.Defaults.json'
    $defaults = Read-JsonFileAsHashtable -Path $coreDefaultsPath

    if ($ModulePath) {
        $moduleDefaultsPath = Join-Path -Path (Join-Path -Path $ModulePath -ChildPath 'Config') -ChildPath 'Module.Defaults.json'
        if ((Test-Path -LiteralPath $moduleDefaultsPath) -and ((Resolve-Path -LiteralPath $moduleDefaultsPath).Path -ne (Resolve-Path -LiteralPath $coreDefaultsPath).Path)) {
            try {
                $moduleDefaults = Read-JsonFileAsHashtable -Path $moduleDefaultsPath
                foreach ($key in $moduleDefaults.Keys) {
                    $defaults[$key] = $moduleDefaults[$key]
                }
            }
            catch {
                Write-Warning "Ignoring invalid defaults file '$moduleDefaultsPath': $($_.Exception.Message)"
            }
        }
    }
    return $defaults
}

function ConvertTo-ConfigValueType {
    <#
    .SYNOPSIS
        Converts a stored value to the type of its default (e.g. "True" -> $true), so values
        written by older versions of tcs.core are read consistently.
    #>
    [CmdletBinding()]
    [OutputType([object])]
    param(
        [AllowNull()]
        [object]$Value,

        [AllowNull()]
        [object]$DefaultValue
    )

    if ($null -eq $Value -or $null -eq $DefaultValue) {
        return $Value
    }
    if ($DefaultValue -is [bool] -and $Value -isnot [bool]) {
        $parsedBool = $false
        if ([bool]::TryParse([string]$Value, [ref]$parsedBool)) {
            return $parsedBool
        }
        return $DefaultValue
    }
    if (($DefaultValue -is [int] -or $DefaultValue -is [long]) -and $Value -is [string]) {
        $parsedInt = 0
        if ([int]::TryParse($Value, [ref]$parsedInt)) {
            return $parsedInt
        }
        return $DefaultValue
    }
    return $Value
}

function Find-ModuleManifestFile {
    <#
    .SYNOPSIS
        Walks up from a path to the nearest folder containing a module manifest (.psd1 with ModuleVersion).
    #>
    [CmdletBinding()]
    [OutputType([System.IO.FileInfo])]
    param(
        [Parameter(Mandatory)]
        [string]$StartPath
    )

    $searchPath = if (Test-Path -LiteralPath $StartPath -PathType Container) { $StartPath } else { Split-Path -Path $StartPath -Parent }

    while (-not [string]::IsNullOrEmpty($searchPath)) {
        $candidates = Get-ChildItem -LiteralPath $searchPath -Filter '*.psd1' -File -ErrorAction SilentlyContinue |
            Where-Object { $_.BaseName -ne 'PSScriptAnalyzerSettings' }
        foreach ($candidate in $candidates) {
            try {
                $data = Import-PowerShellDataFile -LiteralPath $candidate.FullName -ErrorAction Stop
                if ($data.ContainsKey('ModuleVersion')) {
                    return $candidate
                }
            }
            catch {
                Write-Verbose "Skipping '$($candidate.FullName)': $($_.Exception.Message)"
            }
        }
        $parent = Split-Path -Path $searchPath -Parent
        if ($parent -eq $searchPath) {
            break
        }
        $searchPath = $parent
    }
    return $null
}
