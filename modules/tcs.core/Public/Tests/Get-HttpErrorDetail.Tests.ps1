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

Describe 'Get-HttpErrorDetail' {
    BeforeAll {
        $RepoRoot = Split-Path -Path (Split-Path -Path $ModuleRoot -Parent) -Parent
        . (Join-Path -Path $RepoRoot -ChildPath 'tests/Helpers/HttpTestDoubles.ps1')
    }

    Context 'Windows PowerShell 5.1 (WebException with HttpWebResponse)' {
        It 'Returns the status code, description, URI and the body read from the response' {
            $record = New-TestErrorRecord -Exception (New-TestWebException -StatusCode 404 -Description 'Not Found' -Body '{"error":"missing"}')
            $detail = Get-HttpErrorDetail -ErrorRecord $record
            $detail.StatusCode | Should -BeExactly 404
            $detail.StatusDescription | Should -Be 'Not Found'
            $detail.Body | Should -Be '{"error":"missing"}'
            $detail.Uri | Should -Be 'https://api.example.com/items'
            $detail.RetryAfterSeconds | Should -BeNullOrEmpty
        }

        It 'Prefers ErrorDetails.Message for the body' {
            $record = New-TestErrorRecord -Exception (New-TestWebException -StatusCode 400 -Body 'stream body') -ErrorDetails 'details body'
            (Get-HttpErrorDetail -ErrorRecord $record).Body | Should -Be 'details body'
        }

        It 'Reads Retry-After in seconds and as an HTTP date' {
            (Get-HttpErrorDetail -ErrorRecord (New-TestErrorRecord -Exception (New-TestWebException -StatusCode 429 -RetryAfter '12'))).RetryAfterSeconds | Should -Be 12
            $date = [datetime]::UtcNow.AddSeconds(60).ToString('r', [System.Globalization.CultureInfo]::InvariantCulture)
            $seconds = (Get-HttpErrorDetail -ErrorRecord (New-TestErrorRecord -Exception (New-TestWebException -StatusCode 503 -RetryAfter $date))).RetryAfterSeconds
            $seconds | Should -BeGreaterThan 55
            $seconds | Should -BeLessOrEqual 60
        }

        It 'Accepts an exception and finds a wrapped response' {
            $wrapped = New-Object System.Management.Automation.MethodInvocationException -ArgumentList 'Exception calling "GetResponse"', (New-TestWebException -StatusCode 502)
            (Get-HttpErrorDetail -ErrorRecord $wrapped).StatusCode | Should -Be 502
        }
    }

    Context 'PowerShell 7 (HttpResponseException with HttpResponseMessage)' -Skip:($PSVersionTable.PSEdition -eq 'Desktop') {
        It 'Returns the status code, reason, URI, body and Retry-After' {
            $exception = New-TestHttpResponseException -StatusCode 429 -Reason 'Too Many Requests' -Body 'slow down' -RetryAfter ([timespan]::FromSeconds(3))
            $detail = Get-HttpErrorDetail -ErrorRecord (New-TestErrorRecord -Exception $exception)
            $detail.StatusCode | Should -BeExactly 429
            $detail.StatusDescription | Should -Be 'Too Many Requests'
            $detail.Body | Should -Be 'slow down'
            $detail.RetryAfterSeconds | Should -Be 3
            $detail.Uri | Should -Be 'https://api.example.com/items'
        }

        It 'Prefers ErrorDetails.Message for the body' {
            $record = New-TestErrorRecord -Exception (New-TestHttpResponseException -StatusCode 500 -Body 'content') -ErrorDetails '{"message":"boom"}'
            (Get-HttpErrorDetail -ErrorRecord $record).Body | Should -Be '{"message":"boom"}'
        }

        It 'Reads the status code of an HttpRequestException' {
            $exception = New-Object System.Net.Http.HttpRequestException -ArgumentList 'failed', $null, ([System.Net.HttpStatusCode]::BadGateway)
            (Get-HttpErrorDetail -ErrorRecord $exception).StatusCode | Should -Be 502
        }
    }

    It 'Returns nothing for an error without an HTTP response' {
        try { throw [System.Net.Sockets.SocketException]::new() } catch { $record = $_ }
        Get-HttpErrorDetail -ErrorRecord $record | Should -BeNullOrEmpty
        $noResponse = New-Object System.Net.WebException -ArgumentList 'Name resolution failed', ([System.Net.WebExceptionStatus]::NameResolutionFailure)
        Get-HttpErrorDetail -ErrorRecord $noResponse | Should -BeNullOrEmpty
    }

    It 'Accepts errors from the pipeline' {
        $records = @(
            (New-TestErrorRecord -Exception (New-TestWebException -StatusCode 401)),
            (New-TestErrorRecord -Exception (New-TestWebException -StatusCode 403))
        )
        ($records | Get-HttpErrorDetail).StatusCode | Should -Be @(401, 403)
    }
}
