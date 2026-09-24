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

Describe 'ConvertTo-SnakeCase' {
    It "Should convert PascalCase" {
        ConvertTo-SnakeCase -Value "HelloWorld" | Should -Be "hello_world"
    }

    It "Should convert hyphen" {
        ConvertTo-SnakeCase -Value "hello-world" | Should -Be "hello_world"
    }

    It "Should convert camelCase" {
        ConvertTo-SnakeCase -Value "helloWorld" | Should -Be "hello_world"
    }

    It "Should handle empty string" {
        ConvertTo-SnakeCase -Value "" | Should -Be ""
    }
}
