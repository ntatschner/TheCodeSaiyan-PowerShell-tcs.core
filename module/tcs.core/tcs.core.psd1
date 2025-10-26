@{
    ModuleVersion        = '0.1.7'
    GUID                 = 'a61ffd6a-dac4-4de4-a830-0e58a0535eaa'
    Author               = 'Nigel Tatschner'
    CompanyName          = 'TheCodeSaiyan'
    Copyright            = '(c) 2024 Nigel Tatschner. All rights reserved.'
    Description          = 'Core functions required for the suite of modules including configuration management, dynamic parameters, and telemetry collection.'
    CompatiblePSEditions = @('Desktop', 'Core')
    PowerShellVersion    = '5.1'
    RootModule           = 'tcs.core.psm1'
    FunctionsToExport    = @('ConvertTo-CamelCase', 'New-DynamicParameter', 'Set-ModuleConfig')
    CmdletsToExport      = @()
    VariablesToExport    = @()
    AliasesToExport      = @()
    PrivateData          = @{
        PSData = @{
            Tags         = @('Core', 'Utility', 'Module', 'Telemetry', 'Configuration', 'DynamicParameters')
            ProjectUri   = ''
            ReleaseNotes = 'Updated module manifest with explicit function exports and comprehensive help documentation'
        } 
    }
    HelpInfoURI          = 'https://PENDINGHOST/tcs.core/'
}
