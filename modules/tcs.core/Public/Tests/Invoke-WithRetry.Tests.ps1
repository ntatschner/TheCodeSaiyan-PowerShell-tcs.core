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

Describe 'Invoke-WithRetry output and HTTP handling' {
    BeforeAll {
        $RepoRoot = Split-Path -Path (Split-Path -Path $ModuleRoot -Parent) -Parent
        . (Join-Path -Path $RepoRoot -ChildPath 'tests/Helpers/HttpTestDoubles.ps1')
    }

    BeforeEach {
        Mock -ModuleName tcs.core Start-Sleep { }
    }

    It 'Keeps a collection written as one object' {
        $result = Invoke-WithRetry -ScriptBlock { , @(1) }
        , $result | Should -BeOfType [object[]]
        $result.Count | Should -Be 1
        $result[0] | Should -Be 1
    }

    It 'Keeps several objects and writes nothing for no output' {
        $result = Invoke-WithRetry -ScriptBlock { 1; 2; 3 }
        $result | Should -Be @(1, 2, 3)
        @(Invoke-WithRetry -ScriptBlock { }).Count | Should -Be 0
    }

    It 'Discards the output of failed attempts' {
        $script:tries = 0
        $result = Invoke-WithRetry -DelaySeconds 0 -ScriptBlock { $script:tries++; "try $script:tries"; if ($script:tries -lt 2) { throw 'again' } }
        $result | Should -Be 'try 2'
    }

    It 'Does not retry non-terminating errors by default' {
        $script:tries = 0
        $null = Invoke-WithRetry -DelaySeconds 0 -ScriptBlock { $script:tries++; Write-Error 'not terminating' } 2>$null
        $script:tries | Should -Be 1
    }

    It 'Retries non-terminating errors with -RetryOnNonTerminatingError' {
        $script:tries = 0
        $result = Invoke-WithRetry -DelaySeconds 0 -RetryOnNonTerminatingError -ScriptBlock {
            $script:tries++
            if ($script:tries -lt 3) { Write-Error 'not yet' }
            try { throw 'handled' } catch { }
            , @('done')
        } -ErrorVariable errs
        $script:tries | Should -Be 3
        , $result | Should -BeOfType [object[]]
        $result[0] | Should -Be 'done'
    }

    It 'Does not count native stderr lines as errors with -RetryOnNonTerminatingError' {
        $shell = [System.Diagnostics.Process]::GetCurrentProcess().MainModule.FileName
        $script:tries = 0
        $output = @(Invoke-WithRetry -DelaySeconds 0 -RetryOnNonTerminatingError -ScriptBlock {
                $script:tries++
                & $shell -NoProfile -NonInteractive -Command "[Console]::Error.WriteLine('stderr line')"
                'done'
            } 2>$null)
        $script:tries | Should -Be 1
        $output | Should -Be @('done')
    }

    It 'Throws the last non-terminating error when every attempt fails' {
        { Invoke-WithRetry -DelaySeconds 0 -MaxRetries 1 -RetryOnNonTerminatingError -ScriptBlock { Write-Error 'always' } } | Should -Throw 'always'
    }

    It 'Retries a listed status code and throws others at once (Windows PowerShell error shape)' {
        $script:tries = 0
        { Invoke-WithRetry -DelaySeconds 0 -MaxRetries 2 -RetryOnStatusCode 503 -ScriptBlock { $script:tries++; throw (New-TestWebException -StatusCode 503) } } | Should -Throw
        $script:tries | Should -Be 3

        $script:tries = 0
        { Invoke-WithRetry -DelaySeconds 0 -MaxRetries 2 -RetryOnStatusCode 503 -ScriptBlock { $script:tries++; throw (New-TestWebException -StatusCode 404) } } | Should -Throw
        $script:tries | Should -Be 1
    }

    It 'Retries a listed status code and throws others at once (PowerShell 7 error shape)' -Skip:($PSVersionTable.PSEdition -eq 'Desktop') {
        $script:tries = 0
        $result = Invoke-WithRetry -DelaySeconds 0 -RetryOnStatusCode 429 -ScriptBlock {
            $script:tries++
            if ($script:tries -lt 2) { throw (New-TestHttpResponseException -StatusCode 429) }
            'ok'
        }
        $result | Should -Be 'ok'

        $script:tries = 0
        { Invoke-WithRetry -DelaySeconds 0 -RetryOnStatusCode 429 -ScriptBlock { $script:tries++; throw (New-TestHttpResponseException -StatusCode 400) } } | Should -Throw
        $script:tries | Should -Be 1
    }

    It 'Still retries errors without an HTTP response when status codes are listed' {
        $script:tries = 0
        { Invoke-WithRetry -DelaySeconds 0 -MaxRetries 1 -RetryOnStatusCode 503 -ScriptBlock { $script:tries++; throw [System.Net.Sockets.SocketException]::new() } } | Should -Throw
        $script:tries | Should -Be 2
    }

    It 'Honours Retry-After in seconds' {
        { Invoke-WithRetry -DelaySeconds 0 -MaxRetries 1 -ScriptBlock { throw (New-TestWebException -StatusCode 429 -RetryAfter '7') } } | Should -Throw
        Should -Invoke -ModuleName tcs.core Start-Sleep -Times 1 -Exactly -ParameterFilter { $Milliseconds -eq 7000 }
    }

    It 'Honours Retry-After as an HTTP date' {
        $date = [datetime]::UtcNow.AddSeconds(30).ToString('r', [System.Globalization.CultureInfo]::InvariantCulture)
        { Invoke-WithRetry -DelaySeconds 0 -MaxRetries 1 -ScriptBlock { throw (New-TestWebException -StatusCode 503 -RetryAfter $date) } } | Should -Throw
        Should -Invoke -ModuleName tcs.core Start-Sleep -Times 1 -Exactly -ParameterFilter { $Milliseconds -gt 25000 -and $Milliseconds -le 30000 }
    }

    It 'Honours Retry-After on PowerShell 7 and caps it at MaxDelaySeconds' -Skip:($PSVersionTable.PSEdition -eq 'Desktop') {
        { Invoke-WithRetry -DelaySeconds 0 -MaxRetries 1 -MaxDelaySeconds 5 -ScriptBlock { throw (New-TestHttpResponseException -StatusCode 429 -RetryAfter ([timespan]::FromSeconds(60))) } } | Should -Throw
        Should -Invoke -ModuleName tcs.core Start-Sleep -Times 1 -Exactly -ParameterFilter { $Milliseconds -eq 5000 }
    }

    It 'Asks -ShouldRetry with the error record and attempt number' {
        $script:seen = @()
        { Invoke-WithRetry -DelaySeconds 0 -MaxRetries 5 -ShouldRetry { param($errorRecord, $attempt) $script:seen += "$attempt $($errorRecord.Exception.Message)"; $attempt -lt 2 } -ScriptBlock { throw 'nope' } } | Should -Throw 'nope'
        $script:seen | Should -Be @('1 nope', '2 nope')
    }

    It 'Adds at most JitterPercent to the delay' {
        { Invoke-WithRetry -DelaySeconds 1 -MaxRetries 3 -JitterPercent 50 -ScriptBlock { throw 'x' } } | Should -Throw
        Should -Invoke -ModuleName tcs.core Start-Sleep -Times 3 -Exactly -ParameterFilter { $Milliseconds -ge 1000 -and $Milliseconds -le 1500 }
    }
}
