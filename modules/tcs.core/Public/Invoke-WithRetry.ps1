<#
.SYNOPSIS
    Executes a script block with automatic retry logic on failure.

.DESCRIPTION
    The Invoke-WithRetry function wraps a script block in retry logic, automatically
    re-executing it when exceptions occur. It supports configurable retry counts,
    delays with optional exponential backoff and jitter, filtering by exception type, by
    HTTP status code or by a script block, and an optional callback on each retry. If all
    retries are exhausted, the last exception is rethrown.

    HTTP-aware: when a failed request's response has a Retry-After header (a number of
    seconds or an HTTP date), the wait is at least that long, up to MaxDelaySeconds.

    Only terminating errors (exceptions) cause a retry. Non-terminating errors, such as a
    cmdlet that cannot find an item, do not, unless the command in the script block uses
    -ErrorAction Stop or -RetryOnNonTerminatingError is used.

    The output of the successful attempt is written exactly as the script block wrote it:
    a collection written as a single object (for example , @(1)) stays a collection.

.PARAMETER ScriptBlock
    The script block to execute. If execution throws an exception, the function will
    retry according to the configured retry parameters.

.PARAMETER MaxRetries
    The maximum number of retry attempts after the initial failure. Defaults to 3.

.PARAMETER DelaySeconds
    The delay in seconds before the first retry. Fractions are allowed (e.g. 0.5). Defaults to 2.

.PARAMETER BackoffMultiplier
    A multiplier applied to the delay on each successive retry. Set to a value greater
    than 1 for exponential backoff (e.g., 2 doubles the delay each retry). Defaults to 1
    (constant delay).

.PARAMETER MaxDelaySeconds
    The longest delay allowed between retries when backoff is used. Defaults to 300.

.PARAMETER RetryableExceptions
    An optional array of .NET exception types to retry on. When specified, only exceptions
    matching one of these types will trigger a retry. If omitted, all exceptions trigger
    a retry.

.PARAMETER OnRetry
    An optional script block invoked on each retry attempt. It receives the current
    exception as the first argument and the attempt number as the second argument.

.PARAMETER RetryOnStatusCode
    HTTP status codes to retry, for example 429, 502, 503 and 504. An HTTP error with any
    other status code (such as 400 or 404) is thrown at once. Errors without an HTTP
    response (DNS, connection or timeout failures) are still retried. Works with the errors
    of Invoke-RestMethod and Invoke-WebRequest on Windows PowerShell 5.1 and PowerShell 7.

.PARAMETER ShouldRetry
    An optional script block that decides whether an error is retried. It receives the
    ErrorRecord as the first argument and the attempt number as the second, and the error is
    retried only when it returns $true. It is called after the RetryableExceptions and
    RetryOnStatusCode checks, which must also allow the retry.

.PARAMETER JitterPercent
    Adds a random extra delay of up to this percentage of each delay (0-100), so that many
    clients do not retry at the same moment. Defaults to 0 (no jitter).

.PARAMETER RetryOnNonTerminatingError
    Treats a non-terminating error written by the script block (for example by Write-Error,
    or a cmdlet without -ErrorAction Stop) as a failure, so it is retried. Errors of failed
    attempts are not shown; if every attempt fails, the last error is thrown as a
    terminating error. Without this switch, non-terminating errors are passed through and do
    not cause a retry; add -ErrorAction Stop to the commands in the script block instead.

.INPUTS
    None
    This function does not accept pipeline input.

.OUTPUTS
    System.Object
    Returns the output of the successfully executed ScriptBlock. Output of failed attempts
    is discarded.

.EXAMPLE
    Invoke-WithRetry -ScriptBlock { Get-Content "\\server\share\file.txt" } -MaxRetries 5 -DelaySeconds 3

    Attempts to read a file up to 5 times with a 3-second delay between retries.

.EXAMPLE
    Invoke-WithRetry -ScriptBlock { Invoke-RestMethod -Uri $uri } -MaxRetries 4 -DelaySeconds 1 -BackoffMultiplier 2

    Calls a REST endpoint with exponential backoff: 1s, 2s, 4s, 8s delays between retries.

.EXAMPLE
    $onRetry = { param($ex, $attempt) Write-Warning "Retry $attempt : $($ex.Message)" }
    Invoke-WithRetry -ScriptBlock { Connect-Database } -MaxRetries 3 -RetryableExceptions @([System.Net.Sockets.SocketException]) -OnRetry $onRetry

    Retries only on SocketException, invoking a warning callback on each retry.
    Exception types match subclasses too, so [System.Net.WebException] also matches its derived types.

.EXAMPLE
    Invoke-WithRetry -ScriptBlock { Invoke-RestMethod -Uri $uri } -RetryOnStatusCode 429, 502, 503, 504 -DelaySeconds 1 -BackoffMultiplier 2 -JitterPercent 20

    Retries throttled and unavailable responses (honouring Retry-After) with exponential
    backoff and jitter; other HTTP errors such as 404 are thrown at once.

.EXAMPLE
    Invoke-WithRetry -ScriptBlock { Get-Item -Path $path } -RetryOnNonTerminatingError -MaxRetries 5 -DelaySeconds 1

    Retries until the item exists, although Get-Item writes a non-terminating error.

.EXAMPLE
    $retryTransient = { param($errorRecord, $attempt) $errorRecord.Exception.Message -match 'timed out' }
    Invoke-WithRetry -ScriptBlock { Invoke-RestMethod -Uri $uri } -ShouldRetry $retryTransient

    Retries only errors whose message says the request timed out.

.NOTES
    Author: Nigel Tatschner
    Company: TheCodeSaiyan

    This function is part of the tcs.core module and provides robust retry logic
    suitable for network operations, transient fault handling, and resilient scripting.

.LINK
    https://ntatschner.github.io/TheCodeSaiyan-PowerShell-tcs.core/
#>
function Invoke-WithRetry {
    [CmdletBinding()]
    [OutputType([System.Object])]
    param(
        [Parameter(Mandatory = $true, HelpMessage = "The script block to execute with retry logic.")]
        [scriptblock]$ScriptBlock,

        [Parameter(HelpMessage = "Maximum number of retry attempts.")]
        [ValidateRange(0, 1000)]
        [int]$MaxRetries = 3,

        [Parameter(HelpMessage = "Delay in seconds before the first retry.")]
        [ValidateRange(0, 86400)]
        [double]$DelaySeconds = 2,

        [Parameter(HelpMessage = "Multiplier applied to the delay on each successive retry.")]
        [ValidateRange(1, 100)]
        [double]$BackoffMultiplier = 1,

        [Parameter(HelpMessage = "Longest delay allowed between retries.")]
        [ValidateRange(0, 86400)]
        [double]$MaxDelaySeconds = 300,

        [Parameter(HelpMessage = "Optional list of exception types to retry on.")]
        [type[]]$RetryableExceptions,

        [Parameter(HelpMessage = "Optional callback script block invoked on each retry.")]
        [scriptblock]$OnRetry,

        [Parameter(HelpMessage = "HTTP status codes to retry, e.g. 429, 502, 503, 504.")]
        [ValidateRange(100, 599)]
        [int[]]$RetryOnStatusCode,

        [Parameter(HelpMessage = "Script block that decides whether an error is retried.")]
        [scriptblock]$ShouldRetry,

        [Parameter(HelpMessage = "Random extra delay, as a percentage of the delay.")]
        [ValidateRange(0, 100)]
        [int]$JitterPercent = 0,

        [Parameter(HelpMessage = "Treat non-terminating errors as failures and retry them.")]
        [switch]$RetryOnNonTerminatingError
    )

    $attempt = 0

    while ($true) {
        # Output is collected per attempt, so a failed attempt's output is never written
        $output = New-Object System.Collections.Generic.List[object]
        try {
            if ($RetryOnNonTerminatingError) {
                # Errors are merged into the output only to see them; an ErrorRecord that
                # PowerShell also recorded as written (-ErrorVariable) fails the attempt.
                # Errors caught or silenced inside the script block do not count.
                $recordedErrors = $null
                $firstWrittenError = $null
                Invoke-ScriptBlockInChildScope -ScriptBlock $ScriptBlock -ErrorVariable recordedErrors 2>&1 | ForEach-Object -Process {
                    $item = $_
                    $isWrittenError = $false
                    if ($item -is [System.Management.Automation.ErrorRecord]) {
                        foreach ($recorded in @($recordedErrors)) {
                            if ([object]::ReferenceEquals($recorded, $item)) {
                                $isWrittenError = $true
                                break
                            }
                        }
                    }
                    if (-not $isWrittenError) {
                        $output.Add($item)
                    }
                    elseif ($null -eq $firstWrittenError) {
                        $firstWrittenError = $item
                    }
                }
                if ($null -ne $firstWrittenError) {
                    throw $firstWrittenError
                }
            }
            else {
                & $ScriptBlock | ForEach-Object -Process { $output.Add($_) }
            }

            # Write each object as it was output: collections are not unrolled
            foreach ($item in $output) {
                $PSCmdlet.WriteObject($item)
            }
            return
        }
        catch {
            $lastError = $_
            $attempt++
            $httpDetail = Get-HttpResponseInfo -InputObject $lastError

            # Check if we should retry based on exception type
            if ($RetryableExceptions) {
                $shouldRetryError = $false
                foreach ($exType in $RetryableExceptions) {
                    if ($lastError.Exception -is $exType) {
                        $shouldRetryError = $true
                        break
                    }
                }
                if (-not $shouldRetryError) {
                    throw
                }
            }

            # HTTP errors are retried only for the listed status codes; errors without a
            # response (DNS, connection, timeout) are still retried
            if ($RetryOnStatusCode -and $httpDetail -and $null -ne $httpDetail.StatusCode -and $httpDetail.StatusCode -notin $RetryOnStatusCode) {
                throw $lastError
            }

            if ($ShouldRetry -and -not (& $ShouldRetry $lastError $attempt)) {
                throw $lastError
            }

            if ($attempt -gt $MaxRetries) {
                # Rethrow the original error record so callers keep the full error details
                throw $lastError
            }

            # First retry waits DelaySeconds, then DelaySeconds * BackoffMultiplier, ...
            $currentDelay = [Math]::Min($DelaySeconds * [Math]::Pow($BackoffMultiplier, $attempt - 1), $MaxDelaySeconds)

            # A server's Retry-After (seconds or an HTTP date) is honoured, up to MaxDelaySeconds
            if ($httpDetail -and $null -ne $httpDetail.RetryAfterSeconds) {
                $currentDelay = [Math]::Max($currentDelay, [Math]::Min([double]$httpDetail.RetryAfterSeconds, $MaxDelaySeconds))
            }

            if ($JitterPercent -gt 0 -and $currentDelay -gt 0) {
                $jitter = $currentDelay * ($JitterPercent / 100.0) * (Get-Random -Minimum 0.0 -Maximum 1.0)
                $currentDelay = [Math]::Min($currentDelay + $jitter, $MaxDelaySeconds)
            }

            Write-Verbose "Attempt $attempt of $($MaxRetries + 1) failed. Retrying in $([Math]::Round($currentDelay, 3)) seconds... Exception: $($lastError.Exception.Message)"

            if ($OnRetry) {
                & $OnRetry $lastError.Exception $attempt
            }

            if ($currentDelay -gt 0) {
                Start-Sleep -Milliseconds ([int][Math]::Round($currentDelay * 1000))
            }
        }
    }
}
