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

Describe 'ConvertTo-QueryString' {
    It 'Escapes keys and values' {
        ConvertTo-QueryString -InputObject @{ 'the key' = 'a b&c=d/é' } | Should -BeExactly 'the%20key=a%20b%26c%3Dd%2F%C3%A9'
    }

    It 'Keeps the order of an ordered dictionary' {
        ConvertTo-QueryString -InputObject ([ordered]@{ z = 1; a = 2; m = 3 }) | Should -BeExactly 'z=1&a=2&m=3'
    }

    It 'Sorts the keys of a hashtable' {
        ConvertTo-QueryString -InputObject @{ z = 1; a = 2; m = 3 } | Should -BeExactly 'a=2&m=3&z=1'
    }

    It 'Repeats the key for array values and leaves out nulls' {
        ConvertTo-QueryString -InputObject ([ordered]@{ id = @(1, 2, $null); skip = $null; one = @('x') }) | Should -BeExactly 'id=1&id=2&one=x'
    }

    It 'Writes booleans, numbers and dates in an invariant form' {
        $date = [datetime]::new(2026, 9, 24, 10, 30, 0, [System.DateTimeKind]::Utc)
        ConvertTo-QueryString -InputObject ([ordered]@{ flag = $true; off = $false; n = 1.5; when = $date }) |
            Should -BeExactly 'flag=true&off=false&n=1.5&when=2026-09-24T10%3A30%3A00.0000000Z'
    }

    It 'Returns an empty string for an empty dictionary' {
        ConvertTo-QueryString -InputObject @{} | Should -BeExactly ''
    }

    It 'Accepts a dictionary from the pipeline' {
        [ordered]@{ a = 1 } | ConvertTo-QueryString | Should -BeExactly 'a=1'
    }
}
