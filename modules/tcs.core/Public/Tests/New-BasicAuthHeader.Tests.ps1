[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingConvertToSecureStringWithPlainText', '',
    Justification = 'Test values only.')]
param()

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

Describe 'New-BasicAuthHeader' {
    BeforeAll {
        $credential = New-Object System.Management.Automation.PSCredential -ArgumentList 'user@example.com', (ConvertTo-SecureString -String 'tökén:1' -AsPlainText -Force)
        $expected = 'Basic ' + [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes('user@example.com:tökén:1'))
    }

    It 'Returns a hashtable with a UTF-8 Basic Authorization header' {
        $headers = New-BasicAuthHeader -Credential $credential
        $headers | Should -BeOfType [hashtable]
        $headers.Authorization | Should -BeExactly $expected
        $headers.Count | Should -Be 1
    }

    It 'Returns only the value with -ValueOnly' {
        New-BasicAuthHeader -Credential $credential -ValueOnly | Should -BeExactly $expected
    }

    It 'Accepts a credential from the pipeline' {
        ($credential | New-BasicAuthHeader).Authorization | Should -BeExactly $expected
    }
}
