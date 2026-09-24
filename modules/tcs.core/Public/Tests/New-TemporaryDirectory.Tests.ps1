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

Describe 'New-TemporaryDirectory' {
    BeforeAll {
        $script:createdDirs = @()
    }

    It "Should create a directory" {
        $result = New-TemporaryDirectory
        $script:createdDirs += $result.FullName
        Test-Path $result.FullName | Should -BeTrue
    }

    It "Should use Prefix in directory name" {
        $result = New-TemporaryDirectory -Prefix "testprefix"
        $script:createdDirs += $result.FullName
        $result.Name | Should -BeLike "testprefix_*"
    }

    It "Should return DirectoryInfo object" {
        $result = New-TemporaryDirectory
        $script:createdDirs += $result.FullName
        $result | Should -BeOfType [System.IO.DirectoryInfo]
    }

    AfterAll {
        foreach ($dir in $script:createdDirs) {
            if (Test-Path $dir) {
                Remove-Item $dir -Recurse -Force
            }
        }
    }
}

Describe 'New-TemporaryDirectory -WhatIf' {
    It 'Does not create a directory with -WhatIf' {
        $base = Join-Path $TestDrive 'whatif'
        $null = New-Item -Path $base -ItemType Directory -Force
        New-TemporaryDirectory -BasePath $base -WhatIf
        @(Get-ChildItem $base).Count | Should -Be 0
    }
}
