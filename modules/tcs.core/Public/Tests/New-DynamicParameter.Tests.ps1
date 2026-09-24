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

Describe 'New-DynamicParameter' {
    It 'Returns a RuntimeDefinedParameter with the requested name and type' {
        $result = New-DynamicParameter -Name 'Server' -ParameterType ([string]) -Mandatory
        $result.Name | Should -Be 'Server'
        $result.Parameter | Should -BeOfType [System.Management.Automation.RuntimeDefinedParameter]
        $result.Parameter.ParameterType | Should -Be ([string])
        ($result.Parameter.Attributes | Where-Object { $_ -is [System.Management.Automation.ParameterAttribute] }).Mandatory | Should -BeTrue
    }

    It 'Adds a ValidateSet attribute' {
        $result = New-DynamicParameter -Name 'Env' -ParameterType ([string]) -ValidateSet 'Dev', 'Prod'
        ($result.Parameter.Attributes | Where-Object { $_ -is [System.Management.Automation.ValidateSetAttribute] }).ValidValues | Should -Be @('Dev', 'Prod')
    }

    It 'Adds a ValidateRange attribute and requires exactly two values' {
        $result = New-DynamicParameter -Name 'Port' -ParameterType ([int]) -ValidateRange 1, 65535
        $range = $result.Parameter.Attributes | Where-Object { $_ -is [System.Management.Automation.ValidateRangeAttribute] }
        $range.MinRange | Should -Be 1
        $range.MaxRange | Should -Be 65535
        { New-DynamicParameter -Name 'Port' -ParameterType ([int]) -ValidateRange 1 } | Should -Throw
    }

    It 'Adds aliases' {
        $result = New-DynamicParameter -Name 'UserName' -ParameterType ([string]) -Alias 'User', 'U'
        ($result.Parameter.Attributes | Where-Object { $_ -is [System.Management.Automation.AliasAttribute] }).AliasNames | Should -Be @('User', 'U')
    }

    It 'Works inside a DynamicParam block' {
        function Test-Dynamic {
            [CmdletBinding()]
            param()
            DynamicParam {
                $dictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary
                $dynamic = New-DynamicParameter -Name 'Colour' -ParameterType ([string]) -ValidateSet 'Red', 'Blue'
                $dictionary.Add($dynamic.Name, $dynamic.Parameter)
                return $dictionary
            }
            process { $PSBoundParameters['Colour'] }
        }
        Test-Dynamic -Colour Red | Should -Be 'Red'
        { Test-Dynamic -Colour Green } | Should -Throw
    }
}
