<#
.SYNOPSIS
    Sets or updates configuration values for a module in the tcs suite.

.DESCRIPTION
    The Set-ModuleConfig function updates a module's settings file
    (<ApplicationData>/PowerShell/Config/<ModuleName>/Module.Config.json by default). Only the
    settings you pass are changed; other settings are kept. The file is created if it does not
    exist. The change also applies to the current session.

.PARAMETER ModuleName
    The name of the module to configure, for example 'tcs.core' or 'tcs.jira'. Only letters,
    digits, '.', '_' and '-' are allowed, and the name must start with a letter or digit.

.PARAMETER ModuleConfigFilePath
    The full path of a settings file to update, instead of resolving it from ModuleName.

.PARAMETER UpdateWarning
    Whether to show a warning when a newer version of the module is available.

.PARAMETER UpdateCheckIntervalHours
    How often (in hours) to check the PowerShell Gallery for a newer version. Default 24.

.PARAMETER Telemetry
    Whether anonymous usage telemetry is sent.

.PARAMETER TelemetryUri
    The HTTPS ingestion endpoint for telemetry. An empty string clears it.

.PARAMETER TelemetryApiKey
    The API key sent to the telemetry endpoint in the X-API-Key header.

.PARAMETER Setting
    A hashtable of settings to change, for settings that have no parameter of their own (for
    example a module-specific setting from that module's Config/Module.Defaults.json). Each
    value is converted to the type of its default; a value that cannot be converted is
    rejected. A setting also passed as its own parameter (for example -Telemetry) uses the
    parameter value.

.PARAMETER Reset
    Restores the settings file to the defaults before applying any other settings passed. The
    defaults include the module's own Config/Module.Defaults.json when the module is loaded or
    installed.

.PARAMETER PassThru
    Outputs the resulting settings as a hashtable.

.INPUTS
    None
    This function does not accept pipeline input.

.OUTPUTS
    System.Collections.Hashtable
    When PassThru is specified.

.EXAMPLE
    Set-ModuleConfig -ModuleName 'tcs.core' -UpdateWarning $false

    Turns off update warnings for tcs.core.

.EXAMPLE
    Set-ModuleConfig -ModuleName 'tcs.jira' -Telemetry $false

    Turns off telemetry for tcs.jira.

.EXAMPLE
    Set-ModuleConfig -ModuleName 'tcs.jira' -Setting @{ DefaultProject = 'OPS'; PageSize = 100 }

    Changes module-specific settings that have no parameter of their own.

.EXAMPLE
    Set-ModuleConfig -ModuleName 'tcs.core' -Reset -PassThru

    Restores the defaults and returns the resulting settings.

.NOTES
    Author: Nigel Tatschner
    Company: TheCodeSaiyan

.LINK
    Get-ModuleConfig
#>
function Set-ModuleConfig {
    [CmdletBinding(SupportsShouldProcess, DefaultParameterSetName = 'ByName')]
    [OutputType([hashtable])]
    param(
        [Parameter(Mandatory, Position = 0, ParameterSetName = 'ByName', HelpMessage = 'Name of the module to configure.')]
        [ValidateNotNullOrEmpty()]
        [ValidatePattern('^[A-Za-z0-9][A-Za-z0-9._-]*$')]
        [string]$ModuleName,

        [Parameter(Mandatory, ParameterSetName = 'ByPath', HelpMessage = 'Path of the module settings file.')]
        [ValidateNotNullOrEmpty()]
        [string]$ModuleConfigFilePath,

        [Parameter(HelpMessage = 'Show a warning when an update is available.')]
        [bool]$UpdateWarning,

        [Parameter(HelpMessage = 'Hours between update checks.')]
        [ValidateRange(1, 8760)]
        [int]$UpdateCheckIntervalHours,

        [Parameter(HelpMessage = 'Send anonymous usage telemetry.')]
        [bool]$Telemetry,

        [Parameter(HelpMessage = 'HTTPS telemetry ingestion endpoint.')]
        [AllowEmptyString()]
        [ValidateScript({ [string]::IsNullOrEmpty($_) -or $_ -match '^https://' })]
        [string]$TelemetryUri,

        [Parameter(HelpMessage = 'API key for the telemetry endpoint.')]
        [AllowEmptyString()]
        [string]$TelemetryApiKey,

        [Parameter(HelpMessage = 'Other settings to change, as a hashtable.')]
        [ValidateNotNull()]
        [hashtable]$Setting,

        [Parameter(HelpMessage = 'Restore the default settings first.')]
        [switch]$Reset,

        [Parameter(HelpMessage = 'Output the resulting settings.')]
        [switch]$PassThru
    )

    if ($PSCmdlet.ParameterSetName -eq 'ByName') {
        $ModuleConfigFilePath = Join-Path -Path (Join-Path -Path (Get-ModuleConfigRoot) -ChildPath $ModuleName) -ChildPath 'Module.Config.json'
    }
    else {
        $ModuleName = Split-Path -Path (Split-Path -Path $ModuleConfigFilePath -Parent) -Leaf
    }

    # Use the module's own defaults too, so -Reset matches what Get-ModuleConfig creates
    $modulePath = $null
    if (Test-ModuleNameValid -Name $ModuleName) {
        $modulePath = Resolve-ModuleBasePath -ModuleName $ModuleName
    }
    $defaults = Get-DefaultModuleConfig -ModulePath $modulePath

    $settings = @{}
    if ($Reset -or -not (Test-Path -LiteralPath $ModuleConfigFilePath)) {
        foreach ($key in $defaults.Keys) {
            $settings[$key] = $defaults[$key]
        }
    }
    else {
        $existing = Read-JsonFileAsHashtable -Path $ModuleConfigFilePath
        foreach ($key in $existing.Keys) {
            $settings[$key] = ConvertTo-ConfigValueType -Value $existing[$key] -DefaultValue $defaults[$key] -Key $key
        }
    }

    $changes = @{}
    if ($Setting) {
        foreach ($key in $Setting.Keys) {
            $name = [string]$key
            if ([string]::IsNullOrWhiteSpace($name) -or $name -in $script:ReservedConfigKeys) {
                throw "'$name' cannot be set; it describes the loaded module and is not stored."
            }
            $changes[$name] = ConvertTo-ConfigValueType -Value $Setting[$key] -DefaultValue $defaults[$name] -Key $name -Strict
        }
    }
    foreach ($name in @('UpdateWarning', 'UpdateCheckIntervalHours', 'Telemetry', 'TelemetryUri', 'TelemetryApiKey')) {
        if ($PSBoundParameters.ContainsKey($name)) {
            $changes[$name] = $PSBoundParameters[$name]
        }
    }
    foreach ($name in $changes.Keys) {
        $settings[$name] = $changes[$name]
    }

    if ($PSCmdlet.ShouldProcess($ModuleConfigFilePath, 'Update module settings')) {
        Write-JsonFile -Path $ModuleConfigFilePath -Data $settings

        # Keep the current session in step with the file
        if ($script:ModuleConfigCache.ContainsKey($ModuleName)) {
            foreach ($key in $settings.Keys) {
                $script:ModuleConfigCache[$ModuleName][$key] = $settings[$key]
            }
        }
    }

    if ($PassThru) {
        $settings
    }
}
