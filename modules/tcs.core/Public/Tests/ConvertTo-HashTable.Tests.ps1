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

Describe 'ConvertTo-HashTable' {
    It "Should convert PSCustomObject to hashtable" {
        $obj = [PSCustomObject]@{ Name = "Test"; Value = 42 }
        $result = ConvertTo-HashTable -InputObject $obj
        $result | Should -BeOfType [hashtable]
        $result.Keys | Should -Contain 'Name'
        $result.Keys | Should -Contain 'Value'
        $result['Name'] | Should -Be 'Test'
        $result['Value'] | Should -Be 42
    }

    It "Should handle nested objects with -Recurse" {
        $obj = [PSCustomObject]@{
            Name  = "Parent"
            Child = [PSCustomObject]@{ ChildName = "Nested" }
        }
        $result = ConvertTo-HashTable -InputObject $obj -Recurse
        $result | Should -BeOfType [hashtable]
        $result['Child'] | Should -BeOfType [hashtable]
        $result['Child']['ChildName'] | Should -Be 'Nested'
    }

    It "Should exclude empty values with -ExcludeEmpty" {
        $obj = [PSCustomObject]@{ A = "hello"; B = $null; C = "" }
        $result = ConvertTo-HashTable -InputObject $obj -ExcludeEmpty
        $result.Keys | Should -Contain 'A'
        $result.Keys | Should -Not -Contain 'B'
        $result.Keys | Should -Not -Contain 'C'
    }

    It "Should support pipeline input" {
        $obj = [PSCustomObject]@{ Foo = "Bar" }
        $result = $obj | ConvertTo-HashTable
        $result | Should -BeOfType [hashtable]
        $result['Foo'] | Should -Be 'Bar'
    }
}

Describe 'ConvertTo-HashTable options' {
    It 'Keeps property order with -Ordered' {
        $result = [PSCustomObject]@{ Zeta = 1; Alpha = 2; Mid = 3 } | ConvertTo-HashTable -Ordered
        $result | Should -BeOfType [System.Collections.Specialized.OrderedDictionary]
        @($result.Keys) | Should -Be @('Zeta', 'Alpha', 'Mid')
    }

    It 'Accepts a dictionary as input' {
        $result = @{ A = 1 } | ConvertTo-HashTable
        @($result.Keys) | Should -Be @('A')
    }

    It 'Converts nested arrays of objects at any depth with -Recurse' {
        $json = '{"x":[{"a":1}],"y":{"z":[[{"q":1}]]}}' | ConvertFrom-Json
        $result = $json | ConvertTo-HashTable -Recurse
        , $result.x | Should -BeOfType [object[]]
        $result.x[0] | Should -BeOfType [hashtable]
        $result.y.z[0][0] | Should -BeOfType [hashtable]
    }
}
