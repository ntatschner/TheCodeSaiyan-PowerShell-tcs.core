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

Describe 'Get-ModuleConfig' {
    BeforeAll {
        # A fake consumer module with a function in Public/
        $fakeModule = Join-Path -Path $TestDrive -ChildPath 'tcs.fake'
        $null = New-Item -Path (Join-Path $fakeModule 'Public/Tests') -ItemType Directory -Force
        $null = New-Item -Path (Join-Path $fakeModule 'Config') -ItemType Directory -Force
        "@{ ModuleVersion = '1.2.3'; RootModule = 'tcs.fake.psm1' }" | Set-Content -Path (Join-Path $fakeModule 'tcs.fake.psd1')
        "@{ Severity = @('Error') }" | Set-Content -Path (Join-Path $fakeModule 'Public/Tests/PSScriptAnalyzerSettings.psd1')
        '{ "UpdateCheckIntervalHours": 12 }' | Set-Content -Path (Join-Path $fakeModule 'Config/Module.Defaults.json')
        $fakeFunction = Join-Path $fakeModule 'Public/Get-Fake.ps1'
        'function Get-Fake {}' | Set-Content -Path $fakeFunction
        $configFile = Join-Path $env:TCS_CONFIG_ROOT 'tcs.fake/Module.Config.json'
    }

    It 'Finds the owning module manifest and returns a hashtable' {
        $config = Get-ModuleConfig -CommandPath $fakeFunction
        $config | Should -BeOfType [hashtable]
        $config.ModuleName | Should -Be 'tcs.fake'
        $config.ModuleVersion | Should -Be '1.2.3'
        $config.ModulePath | Should -Be $fakeModule
        $config.ModuleConfigFilePath | Should -Be $configFile
    }

    It 'Returns only a hashtable (no stray output) on first run' {
        Remove-Item -Path (Split-Path $configFile) -Recurse -Force -ErrorAction SilentlyContinue
        $output = @(Get-ModuleConfig -CommandPath $fakeFunction 6>$null)
        $output.Count | Should -Be 1
        Test-Path $configFile | Should -BeTrue
    }

    It 'Applies the consumer module defaults over the tcs.core defaults' {
        (Get-ModuleConfig -CommandPath $fakeFunction).UpdateCheckIntervalHours | Should -Be 12
    }

    It 'Reads user settings and converts legacy string values' {
        '{ "UpdateWarning": "False", "Telemetry": "false" }' | Set-Content -Path $configFile
        $config = Get-ModuleConfig -CommandPath $fakeFunction
        $config.UpdateWarning | Should -BeExactly $false
        $config.Telemetry | Should -BeExactly $false
    }

    It 'Does not rewrite an existing settings file' {
        '{ "UpdateWarning": false }' | Set-Content -Path $configFile
        $before = (Get-Item $configFile).LastWriteTimeUtc
        Start-Sleep -Milliseconds 50
        $null = Get-ModuleConfig -CommandPath $fakeFunction
        (Get-Item $configFile).LastWriteTimeUtc | Should -Be $before
    }

    It 'Falls back to defaults with a warning when the settings file is invalid' {
        '{ not json' | Set-Content -Path $configFile
        $config = Get-ModuleConfig -CommandPath $fakeFunction -WarningVariable warnings -WarningAction SilentlyContinue
        $warnings.Count | Should -Be 1
        $config.UpdateWarning | Should -BeTrue
        Remove-Item -Path $configFile -Force
    }

    It 'Uses the caller script path when CommandPath is omitted' {
        $script = Join-Path $fakeModule 'Public/Invoke-Fake.ps1'
        'Get-ModuleConfig' | Set-Content -Path $script
        (& $script).ModuleName | Should -Be 'tcs.fake'
    }

    It 'Throws when no manifest can be found' {
        $orphan = Join-Path $TestDrive 'orphan/script.ps1'
        $null = New-Item -Path $orphan -ItemType File -Force
        { Get-ModuleConfig -CommandPath $orphan } | Should -Throw '*No module manifest*'
    }
}
