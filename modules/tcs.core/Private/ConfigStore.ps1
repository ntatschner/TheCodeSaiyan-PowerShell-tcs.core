<#
.SYNOPSIS
    Internal helpers for reading and writing tcs module configuration files.

.NOTES
    Private helpers for the tcs.core module.
#>

# Per-session cache of resolved module configuration, keyed by module name.
# Populated by Get-ModuleConfig / Set-ModuleConfig and read by Invoke-TelemetryCollection.
$script:ModuleConfigCache = @{}

# Module names become folder names, so only allow a single, safe path segment
$script:ModuleNamePattern = '^[A-Za-z0-9][A-Za-z0-9._-]*$'

# Names of values that describe the loaded module; they are never stored in a settings file
$script:ReservedConfigKeys = @('ModuleName', 'ModulePath', 'ModuleVersion', 'ModuleConfigPath', 'ModuleConfigFilePath')

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

    .DESCRIPTION
        Values that cannot be converted, or that are out of range for a known setting (for
        example UpdateCheckIntervalHours -5), fall back to the default for that key only, so
        one bad value never discards the rest of the settings file.

        With -Strict the function throws instead of falling back. Set-ModuleConfig uses this
        to reject invalid input.
    #>
    [CmdletBinding()]
    [OutputType([object])]
    param(
        [AllowNull()]
        [object]$Value,

        [AllowNull()]
        [object]$DefaultValue,

        [string]$Key,

        [switch]$Strict
    )

    $label = if ($Key) { "Setting '$Key'" } else { 'The value' }
    $result = $Value

    if ($null -ne $Value -and $null -ne $DefaultValue) {
        if ($DefaultValue -is [bool] -and $Value -isnot [bool]) {
            $parsedBool = $false
            if ([bool]::TryParse([string]$Value, [ref]$parsedBool)) {
                $result = $parsedBool
            }
            elseif ($Strict) {
                throw "$label must be `$true or `$false (got '$Value')."
            }
            else {
                Write-Verbose "$label has an invalid value '$Value'; using the default."
                $result = $DefaultValue
            }
        }
        elseif ($DefaultValue -is [int] -or $DefaultValue -is [long]) {
            $parsedNumber = [double]0
            $isNumber = $Value -is [int] -or $Value -is [long] -or $Value -is [double] -or $Value -is [decimal] -or $Value -is [single]
            if (-not $isNumber -and $Value -is [string]) {
                $isNumber = [double]::TryParse($Value, [System.Globalization.NumberStyles]::Float, [System.Globalization.CultureInfo]::InvariantCulture, [ref]$parsedNumber)
            }
            elseif ($isNumber) {
                $parsedNumber = [double]$Value
            }

            if ($isNumber -and $parsedNumber -eq [Math]::Floor($parsedNumber) -and $parsedNumber -ge [int]::MinValue -and $parsedNumber -le [int]::MaxValue) {
                $result = [int]$parsedNumber
            }
            elseif ($Strict) {
                throw "$label must be a whole number (got '$Value')."
            }
            else {
                Write-Verbose "$label has an invalid value '$Value'; using the default."
                $result = $DefaultValue
            }
        }
    }

    # Range and format checks for settings that tcs.core itself uses
    switch ($Key) {
        'UpdateCheckIntervalHours' {
            if ($null -ne $result -and ($result -isnot [int] -or $result -lt 1 -or $result -gt 8760)) {
                if ($Strict) {
                    throw "$label must be between 1 and 8760 (got '$Value')."
                }
                Write-Verbose "$label is out of range ('$Value'); using the default."
                $result = $DefaultValue
            }
        }
        'TelemetryUri' {
            if ($Strict -and -not [string]::IsNullOrEmpty([string]$result) -and [string]$result -notmatch '^https://') {
                throw "$label must be an https:// address or empty (got '$Value')."
            }
        }
    }

    return $result
}

function Get-MaskedModuleConfig {
    <#
    .SYNOPSIS
        Returns a copy of a settings hashtable with secrets (the telemetry API key) masked, for output.
    #>
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [Parameter(Mandatory)]
        [hashtable]$Config
    )

    $copy = @{}
    foreach ($key in $Config.Keys) {
        $copy[$key] = $Config[$key]
    }
    if (-not [string]::IsNullOrEmpty([string]$copy['TelemetryApiKey'])) {
        $copy['TelemetryApiKey'] = '********'
    }
    return $copy
}

function Test-ModuleNameValid {
    <#
    .SYNOPSIS
        Returns $true when a module name is safe to use as a single folder name.
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [AllowNull()]
        [AllowEmptyString()]
        [string]$Name
    )

    return (-not [string]::IsNullOrEmpty($Name) -and $Name -match $script:ModuleNamePattern)
}

function Resolve-ModuleBasePath {
    <#
    .SYNOPSIS
        Finds the folder of an installed or loaded module, so its own defaults can be read.
        Returns $null when the module cannot be found.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [string]$ModuleName
    )

    $cached = $script:ModuleConfigCache[$ModuleName]
    if ($cached -and $cached['ModulePath']) {
        return [string]$cached['ModulePath']
    }

    $module = Get-Module -Name $ModuleName -ErrorAction SilentlyContinue |
        Sort-Object -Property Version -Descending | Select-Object -First 1
    if (-not $module) {
        $module = Get-Module -Name $ModuleName -ListAvailable -ErrorAction SilentlyContinue |
            Sort-Object -Property Version -Descending | Select-Object -First 1
    }
    if ($module) {
        return [string]$module.ModuleBase
    }
    return $null
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
