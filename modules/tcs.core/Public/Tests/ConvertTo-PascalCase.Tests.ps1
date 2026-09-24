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

Describe 'ConvertTo-PascalCase' {
    It "Should convert underscore separated" {
        ConvertTo-PascalCase -Value "hello_world" | Should -Be "HelloWorld"
    }

    It "Should convert hyphen separated" {
        ConvertTo-PascalCase -Value "hello-world" | Should -Be "HelloWorld"
    }

    It "Should convert space separated" {
        ConvertTo-PascalCase -Value "hello world" | Should -Be "HelloWorld"
    }

    It "Should convert camelCase" {
        ConvertTo-PascalCase -Value "helloWorld" | Should -Be "HelloWorld"
    }

    It "Should handle empty string" {
        ConvertTo-PascalCase -Value "" | Should -Be ""
    }

    It "Should support pipeline" {
        "test_value" | ConvertTo-PascalCase | Should -Be "TestValue"
    }
}
