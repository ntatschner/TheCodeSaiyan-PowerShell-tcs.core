<#
.SYNOPSIS
    Retrieves the configuration for a PowerShell module in the tcs suite.

.DESCRIPTION
    The Get-ModuleConfig function finds the module that owns CommandPath (by walking up to the
    nearest module manifest) and returns its configuration as a hashtable.

    The configuration is built from:
      1. The tcs.core defaults (Config/Module.Defaults.json in tcs.core).
      2. The calling module's own Config/Module.Defaults.json, if it has one.
      3. The user's settings file:
         <ApplicationData>/PowerShell/Config/<ModuleName>/Module.Config.json
         (the TCS_CONFIG_ROOT environment variable overrides the root folder).

    The settings file is created with the defaults the first time a module is loaded so users
    can edit it. After that it is only read; change settings with Set-ModuleConfig.

    A value that cannot be read as the type of its default, or that is out of range (for
    example UpdateCheckIntervalHours below 1), is replaced by the default for that setting
    only; the other settings in the file are still used.

    The returned hashtable also contains ModuleName, ModulePath, ModuleVersion,
    ModuleConfigPath and ModuleConfigFilePath.

.PARAMETER CommandPath
    The path of the calling script or module file, normally $PSCommandPath. When omitted, the
    path of the calling script is used.

.INPUTS
    None
    This function does not accept pipeline input.

.OUTPUTS
    System.Collections.Hashtable

.EXAMPLE
    $config = Get-ModuleConfig -CommandPath $PSCommandPath

    Retrieves the configuration for the module that contains the calling script.

.EXAMPLE
    if ((Get-ModuleConfig).UpdateWarning) { 'Update warnings are on' }

    Uses the calling script's path automatically.

.NOTES
    Author: Nigel Tatschner
    Company: TheCodeSaiyan

    If the settings file cannot be written (for example a read-only profile), defaults are
    used for the session and a verbose message is written.

.LINK
    Set-ModuleConfig
#>
function Get-ModuleConfig {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param (
        [Parameter(Position = 0)]
        [ValidateNotNullOrEmpty()]
        [string]$CommandPath
    )

    if (-not $PSBoundParameters.ContainsKey('CommandPath')) {
        $CommandPath = (Get-PSCallStack)[1].ScriptName
        if ([string]::IsNullOrEmpty($CommandPath)) {
            throw 'CommandPath was not supplied and the caller has no script path. Pass -CommandPath $PSCommandPath.'
        }
    }
    Write-Verbose "CommandPath: $CommandPath"

    $manifest = Find-ModuleManifestFile -StartPath $CommandPath
    if (-not $manifest) {
        throw "No module manifest (.psd1) was found in or above '$CommandPath'."
    }

    $moduleName = $manifest.BaseName
    $modulePath = $manifest.DirectoryName
    $moduleVersion = (Import-PowerShellDataFile -LiteralPath $manifest.FullName).ModuleVersion
    $moduleConfigPath = Join-Path -Path (Get-ModuleConfigRoot) -ChildPath $moduleName
    $moduleConfigFilePath = Join-Path -Path $moduleConfigPath -ChildPath 'Module.Config.json'
    Write-Verbose "Module '$moduleName' $moduleVersion at '$modulePath'; config file '$moduleConfigFilePath'"

    $defaults = Get-DefaultModuleConfig -ModulePath $modulePath
    $config = @{}
    foreach ($key in $defaults.Keys) {
        $config[$key] = $defaults[$key]
    }

    if (Test-Path -LiteralPath $moduleConfigFilePath) {
        try {
            $userConfig = Read-JsonFileAsHashtable -Path $moduleConfigFilePath
            foreach ($key in $userConfig.Keys) {
                $config[$key] = ConvertTo-ConfigValueType -Value $userConfig[$key] -DefaultValue $defaults[$key] -Key $key
            }
        }
        catch {
            Write-Warning "The settings file '$moduleConfigFilePath' could not be read and defaults are being used. Fix or remove the file, or run 'Set-ModuleConfig -ModuleName $moduleName -Reset'. Error: $($_.Exception.Message)"
        }
    }
    else {
        try {
            Write-JsonFile -Path $moduleConfigFilePath -Data $defaults
            if ($config['Telemetry'] -eq $true -and $env:TCS_TELEMETRY_OPTOUT -notin @('1', 'true', 'yes')) {
                Write-Information -MessageData ("$moduleName collects anonymous usage telemetry (command name, duration, success and PowerShell/OS version; no user, machine or path details). " +
                    "Turn it off with 'Set-ModuleConfig -ModuleName $moduleName -Telemetry `$false' or by setting the TCS_TELEMETRY_OPTOUT environment variable to 1.") -InformationAction Continue
            }
        }
        catch {
            Write-Verbose "Could not create '$moduleConfigFilePath'; using defaults for this session. $($_.Exception.Message)"
        }
    }

    # Values derived from the loaded module always win over anything stored in the file
    $config['ModuleName'] = $moduleName
    $config['ModulePath'] = $modulePath
    $config['ModuleVersion'] = $moduleVersion
    $config['ModuleConfigPath'] = $moduleConfigPath
    $config['ModuleConfigFilePath'] = $moduleConfigFilePath

    $script:ModuleConfigCache[$moduleName] = $config
    return $config
}
