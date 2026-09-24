@{
    ModuleVersion        = '0.3.0'
    GUID                 = 'a61ffd6a-dac4-4de4-a830-0e58a0535eaa'
    Author               = 'Nigel Tatschner'
    CompanyName          = 'TheCodeSaiyan'
    Copyright            = '(c) 2024-2026 Nigel Tatschner. All rights reserved.'
    Description          = 'Core functions required for the suite of modules including configuration management, dynamic parameters, telemetry collection, structured logging, retry logic, string casing utilities, and config value protection.'
    CompatiblePSEditions = @('Desktop', 'Core')
    PowerShellVersion    = '5.1'
    RootModule           = 'tcs.core.psm1'
    FunctionsToExport    = @(
        'Complete-TcsTelemetry',
        'ConvertTo-CamelCase',
        'ConvertTo-HashTable',
        'ConvertTo-KebabCase',
        'ConvertTo-PascalCase',
        'ConvertTo-SnakeCase',
        'Get-ModuleConfig',
        'Get-ModuleStatus',
        'Get-ParameterValues',
        'Invoke-TcsCommand',
        'Invoke-TelemetryCollection',
        'Invoke-WithRetry',
        'New-DynamicParameter',
        'New-TemporaryDirectory',
        'Protect-ConfigValue',
        'Set-ModuleConfig',
        'Start-TcsTelemetry',
        'Test-IsElevated',
        'Unprotect-ConfigValue',
        'Write-Log'
    )
    CmdletsToExport      = @()
    VariablesToExport    = @()
    AliasesToExport      = @()
    PrivateData          = @{
        PSData = @{
            Tags         = @('Core', 'Utility', 'Module', 'Telemetry', 'Configuration', 'DynamicParameters', 'Logging', 'Retry', 'StringCasing', 'Security', 'PSEdition_Desktop', 'PSEdition_Core', 'Windows', 'Linux', 'MacOS')
            ProjectUri   = 'https://github.com/ntatschner/TheCodeSaiyan-PowerShell-tcs.core'
            LicenseUri   = 'https://github.com/ntatschner/TheCodeSaiyan-PowerShell-tcs.core/blob/main/LICENSE'
            ReleaseNotes = 'https://github.com/ntatschner/TheCodeSaiyan-PowerShell-tcs.core/blob/main/CHANGELOG.md'
        }
    }
    HelpInfoURI          = 'https://ntatschner.github.io/TheCodeSaiyan-PowerShell-tcs.core/'
}
