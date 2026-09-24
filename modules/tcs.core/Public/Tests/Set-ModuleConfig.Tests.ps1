BeforeAll {
    $env:TCS_CONFIG_ROOT = Join-Path -Path $TestDrive -ChildPath 'config'
    $env:TCS_SKIP_UPDATE_CHECK = '1'
    $env:TCS_TELEMETRY_OPTOUT = '1'
    $ModuleRoot = Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent
    Import-Module -Name (Join-Path -Path $ModuleRoot -ChildPath 'tcs.core.psd1') -Force
}

AfterAll {
    Remove-Module -Name tcs.core -Force -ErrorAction SilentlyContinue
}

Describe 'Set-ModuleConfig' {
    BeforeEach {
        $configFile = Join-Path -Path $env:TCS_CONFIG_ROOT -ChildPath 'tcs.test/Module.Config.json'
        if (Test-Path -Path $configFile) { Remove-Item -Path $configFile -Force }
    }

    It 'Creates the settings file from defaults when it does not exist' {
        Set-ModuleConfig -ModuleName 'tcs.test' -UpdateWarning $false
        $saved = Get-Content -Path $configFile -Raw | ConvertFrom-Json
        $saved.UpdateWarning | Should -BeFalse
        $saved.Telemetry | Should -BeTrue
        $saved.UpdateCheckIntervalHours | Should -Be 24
    }

    It 'Only changes the settings that are passed' {
        Set-ModuleConfig -ModuleName 'tcs.test' -Telemetry $false
        Set-ModuleConfig -ModuleName 'tcs.test' -UpdateWarning $false
        $saved = Get-Content -Path $configFile -Raw | ConvertFrom-Json
        $saved.Telemetry | Should -BeFalse
        $saved.UpdateWarning | Should -BeFalse
    }

    It 'Converts legacy string booleans to real booleans' {
        $null = New-Item -Path (Split-Path $configFile) -ItemType Directory -Force
        '{ "UpdateWarning": "True", "BasicTelemetry": "True" }' | Set-Content -Path $configFile
        $result = Set-ModuleConfig -ModuleName 'tcs.test' -Telemetry $false -PassThru
        $result.UpdateWarning | Should -BeOfType [bool]
        $result.UpdateWarning | Should -BeTrue
    }

    It 'Restores defaults with -Reset' {
        Set-ModuleConfig -ModuleName 'tcs.test' -UpdateWarning $false -Telemetry $false
        $result = Set-ModuleConfig -ModuleName 'tcs.test' -Reset -PassThru
        $result.UpdateWarning | Should -BeTrue
        $result.Telemetry | Should -BeTrue
    }

    It 'Accepts an explicit settings file path' {
        $path = Join-Path -Path $TestDrive -ChildPath 'custom/tcs.custom/Module.Config.json'
        Set-ModuleConfig -ModuleConfigFilePath $path -UpdateCheckIntervalHours 48
        (Get-Content -Path $path -Raw | ConvertFrom-Json).UpdateCheckIntervalHours | Should -Be 48
    }

    It 'Rejects a non-HTTPS telemetry endpoint' {
        { Set-ModuleConfig -ModuleName 'tcs.test' -TelemetryUri 'http://example.com' } | Should -Throw
    }

    It 'Does not write anything with -WhatIf' {
        Set-ModuleConfig -ModuleName 'tcs.test' -UpdateWarning $false -WhatIf
        Test-Path -Path $configFile | Should -BeFalse
    }

    It 'Updates the configuration of the current session' {
        $null = Get-ModuleConfig -CommandPath (Join-Path $ModuleRoot 'tcs.core.psm1')
        Set-ModuleConfig -ModuleName 'tcs.core' -Telemetry $false
        InModuleScope tcs.core { $script:ModuleConfigCache['tcs.core'].Telemetry } | Should -BeFalse
        Set-ModuleConfig -ModuleName 'tcs.core' -Reset
    }
}
