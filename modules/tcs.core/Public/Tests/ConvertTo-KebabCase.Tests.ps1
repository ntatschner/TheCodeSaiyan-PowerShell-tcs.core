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

Describe 'ConvertTo-KebabCase' {
    It "Should convert PascalCase" {
        ConvertTo-KebabCase -Value "HelloWorld" | Should -Be "hello-world"
    }

    It "Should convert underscore" {
        ConvertTo-KebabCase -Value "hello_world" | Should -Be "hello-world"
    }

    It "Should convert camelCase" {
        ConvertTo-KebabCase -Value "helloWorld" | Should -Be "hello-world"
    }

    It "Should handle empty string" {
        ConvertTo-KebabCase -Value "" | Should -Be ""
    }
}
