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

Describe 'Get-ParameterValues' {
    It 'Removes common parameters and null values' {
        $bound = @{ Name = 'a'; Empty = $null; Verbose = $true; WhatIf = $true; ErrorAction = 'Stop' }
        $result = Get-ParameterValues -PSBoundParametersHash $bound
        @($result.Keys) | Should -Be @('Name')
    }

    It 'Applies Exclude and Include' {
        $bound = @{ A = 1; B = 2; C = 3 }
        (Get-ParameterValues -PSBoundParametersHash $bound -Exclude 'A').Keys | Sort-Object | Should -Be @('B', 'C')
        @((Get-ParameterValues -PSBoundParametersHash $bound -Include 'C').Keys) | Should -Be @('C')
    }
}

Describe 'Get-ParameterValues deprecation' {
    It 'Warns once per session and keeps working' {
        InModuleScope tcs.core { $script:DeprecationWarningsShown.Clear() }
        $warnings = $null
        $first = Get-ParameterValues -PSBoundParametersHash @{ A = 1 } -WarningVariable warnings -WarningAction SilentlyContinue
        $null = Get-ParameterValues -PSBoundParametersHash @{ A = 1 } -WarningVariable +warnings -WarningAction SilentlyContinue
        $first.A | Should -Be 1
        @($warnings).Count | Should -Be 1
        [string]$warnings[0] | Should -Match 'Get-ParameterValues is deprecated and will be removed in tcs.core 1.0'
    }
}
