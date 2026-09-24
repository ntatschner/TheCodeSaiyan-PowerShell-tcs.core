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

    It 'Uses the module''s own defaults with -Reset' {
        $fakeModule = Join-Path -Path $TestDrive -ChildPath 'mods/tcs.resetfake'
        $null = New-Item -Path (Join-Path $fakeModule 'Config') -ItemType Directory -Force
        "@{ ModuleVersion = '1.0.0'; RootModule = 'tcs.resetfake.psm1' }" | Set-Content -Path (Join-Path $fakeModule 'tcs.resetfake.psd1')
        '' | Set-Content -Path (Join-Path $fakeModule 'tcs.resetfake.psm1')
        '{ "BaseUrl": "https://example.com", "UpdateWarning": false }' | Set-Content -Path (Join-Path $fakeModule 'Config/Module.Defaults.json')
        $null = Get-ModuleConfig -CommandPath (Join-Path $fakeModule 'tcs.resetfake.psm1')
        Set-ModuleConfig -ModuleName 'tcs.resetfake' -Setting @{ BaseUrl = 'https://other.example.com' } -UpdateWarning $true

        $result = Set-ModuleConfig -ModuleName 'tcs.resetfake' -Reset -PassThru
        $result.BaseUrl | Should -Be 'https://example.com'
        $result.UpdateWarning | Should -BeFalse
    }

    It 'Finds the module defaults of an available module that is not loaded' {
        $modules = Join-Path -Path $TestDrive -ChildPath 'psmodules'
        $fakeModule = Join-Path -Path $modules -ChildPath 'tcs.availfake'
        $null = New-Item -Path (Join-Path $fakeModule 'Config') -ItemType Directory -Force
        "@{ ModuleVersion = '1.0.0'; RootModule = 'tcs.availfake.psm1' }" | Set-Content -Path (Join-Path $fakeModule 'tcs.availfake.psd1')
        '' | Set-Content -Path (Join-Path $fakeModule 'tcs.availfake.psm1')
        '{ "PageSize": 50 }' | Set-Content -Path (Join-Path $fakeModule 'Config/Module.Defaults.json')
        $oldPath = $env:PSModulePath
        try {
            $env:PSModulePath = $modules + [System.IO.Path]::PathSeparator + $env:PSModulePath
            $result = Set-ModuleConfig -ModuleName 'tcs.availfake' -Reset -PassThru
            $result.PageSize | Should -Be 50
            (Set-ModuleConfig -ModuleName 'tcs.availfake' -Setting @{ PageSize = '75' } -PassThru).PageSize | Should -BeExactly 75
        }
        finally {
            $env:PSModulePath = $oldPath
        }
    }

    It 'Sets arbitrary settings with -Setting, typed against the defaults' {
        $result = Set-ModuleConfig -ModuleName 'tcs.test' -Setting @{ UpdateWarning = 'false'; CustomValue = 'abc' } -PassThru
        $result.UpdateWarning | Should -BeExactly $false
        $result.CustomValue | Should -Be 'abc'
        (Get-Content -Path $configFile -Raw | ConvertFrom-Json).CustomValue | Should -Be 'abc'
    }

    It 'Lets explicit parameters win over -Setting' {
        $result = Set-ModuleConfig -ModuleName 'tcs.test' -Setting @{ Telemetry = $true } -Telemetry $false -PassThru
        $result.Telemetry | Should -BeFalse
    }

    It 'Rejects invalid values in -Setting' {
        { Set-ModuleConfig -ModuleName 'tcs.test' -Setting @{ UpdateCheckIntervalHours = -5 } } | Should -Throw '*between 1 and 8760*'
        { Set-ModuleConfig -ModuleName 'tcs.test' -Setting @{ Telemetry = 'maybe' } } | Should -Throw
        { Set-ModuleConfig -ModuleName 'tcs.test' -Setting @{ TelemetryUri = 'http://example.com' } } | Should -Throw
        { Set-ModuleConfig -ModuleName 'tcs.test' -Setting @{ ModulePath = 'x' } } | Should -Throw
        Test-Path -Path $configFile | Should -BeFalse
    }

    It 'Rejects module names that are not a single safe folder name' -ForEach @(
        @{ Name = '../../escaped' }, @{ Name = '..' }, @{ Name = 'a/b' }, @{ Name = 'a\b' }, @{ Name = '.hidden' }
    ) {
        { Set-ModuleConfig -ModuleName $Name -Telemetry $false } | Should -Throw
        Test-Path -Path (Join-Path $TestDrive 'escaped') | Should -BeFalse
    }

    It 'Repairs an invalid stored value when saving' {
        $null = New-Item -Path (Split-Path $configFile) -ItemType Directory -Force
        '{ "UpdateCheckIntervalHours": -5 }' | Set-Content -Path $configFile
        (Set-ModuleConfig -ModuleName 'tcs.test' -Telemetry $false -PassThru).UpdateCheckIntervalHours | Should -Be 24
    }

    It 'Updates the configuration of the current session' {
        $null = Get-ModuleConfig -CommandPath (Join-Path $ModuleRoot 'tcs.core.psm1')
        Set-ModuleConfig -ModuleName 'tcs.core' -Telemetry $false
        InModuleScope tcs.core { $script:ModuleConfigCache['tcs.core'].Telemetry } | Should -BeFalse
        Set-ModuleConfig -ModuleName 'tcs.core' -Reset
    }
}
