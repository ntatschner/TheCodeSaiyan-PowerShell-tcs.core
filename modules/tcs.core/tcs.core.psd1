@{
    ModuleVersion        = '0.2.0'
    GUID                 = 'a61ffd6a-dac4-4de4-a830-0e58a0535eaa'
    Author               = 'Nigel Tatschner'
    CompanyName          = 'TheCodeSaiyan'
    Copyright            = '(c) 2024 Nigel Tatschner. All rights reserved.'
    Description          = 'Core functions required for the suite of modules including configuration management, dynamic parameters, telemetry collection, structured logging, retry logic, string casing utilities, and config value protection.'
    CompatiblePSEditions = @('Desktop', 'Core')
    PowerShellVersion    = '5.1'
    RootModule           = 'tcs.core.psm1'
    FunctionsToExport    = @(
        'ConvertTo-CamelCase',
        'ConvertTo-HashTable',
        'ConvertTo-KebabCase',
        'ConvertTo-PascalCase',
        'ConvertTo-SnakeCase',
        'Invoke-WithRetry',
        'New-DynamicParameter',
        'New-TemporaryDirectory',
        'Protect-ConfigValue',
        'Set-ModuleConfig',
        'Test-IsElevated',
        'Unprotect-ConfigValue',
        'Write-Log',
        'Invoke-TelemetryCollection',
        'Get-ModuleConfig',
        'Get-ModuleStatus',
        'Get-ParameterValues'
    )
    CmdletsToExport      = @()
    VariablesToExport    = @()
    AliasesToExport      = @()
    PrivateData          = @{
        PSData = @{
            Tags         = @('Core', 'Utility', 'Module', 'Telemetry', 'Configuration', 'DynamicParameters', 'Logging', 'Retry', 'StringCasing', 'Security')
            ProjectUri   = 'https://github.com/ntatschner/TheCodeSaiyan-PowerShell-tcs.core'
            ReleaseNotes = 'v0.2.0: Added Write-Log, Invoke-WithRetry, ConvertTo-HashTable, Test-IsElevated, New-TemporaryDirectory, Protect/Unprotect-ConfigValue, ConvertTo-PascalCase/KebabCase/SnakeCase. Improved ConvertTo-CamelCase, Set-ModuleConfig, Get-ModuleConfig, Get-ModuleStatus, New-DynamicParameter, Get-ParameterValues. Security hardening for telemetry. Bug fixes.'
        } 
    }
    HelpInfoURI          = 'https://ntatschner.github.io/TheCodeSaiyan-PowerShell-tcs.core/'
}
