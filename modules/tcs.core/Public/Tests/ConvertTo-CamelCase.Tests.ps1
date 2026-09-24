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

Describe 'ConvertTo-CamelCase' {
    It 'Converts <Value> to <Expected>' -TestCases @(
        @{ Value = 'HelloWorld'; Expected = 'helloWorld' }
        @{ Value = 'hello_world'; Expected = 'helloWorld' }
        @{ Value = 'hello-world'; Expected = 'helloWorld' }
        @{ Value = 'hello world'; Expected = 'helloWorld' }
        @{ Value = 'XMLParser'; Expected = 'xmlParser' }
        @{ Value = 'XML'; Expected = 'xml' }
    ) {
        ConvertTo-CamelCase -Value $Value | Should -BeExactly $Expected
    }

    It 'Returns an empty string unchanged' {
        ConvertTo-CamelCase -Value '' | Should -BeExactly ''
    }

    It 'Accepts pipeline input' {
        'MyProperty', 'other_value' | ConvertTo-CamelCase | Should -Be @('myProperty', 'otherValue')
    }

    It 'Is not affected by the current culture' {
        $previous = [System.Threading.Thread]::CurrentThread.CurrentCulture
        try {
            [System.Threading.Thread]::CurrentThread.CurrentCulture = 'tr-TR'
            ConvertTo-CamelCase -Value 'ID_INFO' | Should -BeExactly 'idInfo'
        }
        finally {
            [System.Threading.Thread]::CurrentThread.CurrentCulture = $previous
        }
    }
}
