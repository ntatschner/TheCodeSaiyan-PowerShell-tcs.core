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

Describe 'Invoke-WithRetry' {
    It "Should return result on success" {
        $result = Invoke-WithRetry -ScriptBlock { "hello" }
        $result | Should -Be "hello"
    }

    It "Should retry on failure" {
        $script:counter = 0
        $result = Invoke-WithRetry -ScriptBlock {
            $script:counter++
            if ($script:counter -lt 3) {
                throw "Transient failure"
            }
            "success"
        } -MaxRetries 5 -DelaySeconds 0
        $result | Should -Be "success"
        $script:counter | Should -Be 3
    }

    It "Should throw after max retries exhausted" {
        {
            Invoke-WithRetry -ScriptBlock {
                throw "Permanent failure"
            } -MaxRetries 2 -DelaySeconds 0
        } | Should -Throw
    }

    It "Should apply delay between retries with BackoffMultiplier without error" {
        $script:counter = 0
        {
            Invoke-WithRetry -ScriptBlock {
                $script:counter++
                if ($script:counter -lt 2) {
                    throw "Transient"
                }
                "done"
            } -MaxRetries 3 -DelaySeconds 0 -BackoffMultiplier 2
        } | Should -Not -Throw
    }
}

Describe 'Invoke-WithRetry timing and errors' {
    BeforeEach {
        Mock -ModuleName tcs.core Start-Sleep { }
    }

    It 'Waits DelaySeconds before the first retry, then applies the backoff' {
        { Invoke-WithRetry -ScriptBlock { throw 'x' } -MaxRetries 3 -DelaySeconds 1 -BackoffMultiplier 2 } | Should -Throw
        Should -Invoke -ModuleName tcs.core Start-Sleep -Times 1 -Exactly -ParameterFilter { $Milliseconds -eq 1000 }
        Should -Invoke -ModuleName tcs.core Start-Sleep -Times 1 -Exactly -ParameterFilter { $Milliseconds -eq 2000 }
        Should -Invoke -ModuleName tcs.core Start-Sleep -Times 1 -Exactly -ParameterFilter { $Milliseconds -eq 4000 }
    }

    It 'Supports fractional delays' {
        { Invoke-WithRetry -ScriptBlock { throw 'x' } -MaxRetries 1 -DelaySeconds 0.25 } | Should -Throw
        Should -Invoke -ModuleName tcs.core Start-Sleep -Times 1 -Exactly -ParameterFilter { $Milliseconds -eq 250 }
    }

    It 'Caps the delay at MaxDelaySeconds' {
        { Invoke-WithRetry -ScriptBlock { throw 'x' } -MaxRetries 2 -DelaySeconds 10 -BackoffMultiplier 10 -MaxDelaySeconds 15 } | Should -Throw
        Should -Invoke -ModuleName tcs.core Start-Sleep -Times 1 -Exactly -ParameterFilter { $Milliseconds -eq 15000 }
    }

    It 'Rethrows the original exception type after the last attempt' {
        { Invoke-WithRetry -ScriptBlock { throw [System.IO.IOException]::new('disk') } -MaxRetries 1 -DelaySeconds 0 } |
            Should -Throw -ExceptionType ([System.IO.IOException])
    }

    It 'Does not retry exceptions outside RetryableExceptions' {
        $script:calls = 0
        { Invoke-WithRetry -ScriptBlock { $script:calls++; throw [System.ArgumentException]::new('bad') } -RetryableExceptions ([System.IO.IOException]) -DelaySeconds 0 } |
            Should -Throw -ExceptionType ([System.ArgumentException])
        $script:calls | Should -Be 1
    }

    It 'Passes the exception and attempt number to OnRetry' {
        $script:seen = @()
        { Invoke-WithRetry -ScriptBlock { throw 'x' } -MaxRetries 2 -DelaySeconds 0 -OnRetry { param($ex, $n) $script:seen += $n } } | Should -Throw
        $script:seen | Should -Be @(1, 2)
    }
}
