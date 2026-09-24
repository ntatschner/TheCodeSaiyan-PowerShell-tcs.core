<#
.SYNOPSIS
    Executes a script block with automatic retry logic on failure.

.DESCRIPTION
    The Invoke-WithRetry function wraps a script block in retry logic, automatically
    re-executing it when exceptions occur. It supports configurable retry counts,
    delays with optional exponential backoff, filtering by exception type, and an
    optional callback on each retry. If all retries are exhausted, the last exception
    is rethrown.

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

.INPUTS
    None
    This function does not accept pipeline input.

.OUTPUTS
    System.Object
    Returns the output of the successfully executed ScriptBlock.

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
        [scriptblock]$OnRetry
    )

    $attempt = 0

    while ($true) {
        try {
            return (& $ScriptBlock)
        }
        catch {
            $lastError = $_
            $attempt++

            # Check if we should retry based on exception type
            if ($RetryableExceptions) {
                $shouldRetry = $false
                foreach ($exType in $RetryableExceptions) {
                    if ($lastError.Exception -is $exType) {
                        $shouldRetry = $true
                        break
                    }
                }
                if (-not $shouldRetry) {
                    throw
                }
            }

            if ($attempt -gt $MaxRetries) {
                # Rethrow the original error record so callers keep the full error details
                throw $lastError
            }

            # First retry waits DelaySeconds, then DelaySeconds * BackoffMultiplier, ...
            $currentDelay = [Math]::Min($DelaySeconds * [Math]::Pow($BackoffMultiplier, $attempt - 1), $MaxDelaySeconds)

            Write-Verbose "Attempt $attempt of $($MaxRetries + 1) failed. Retrying in $currentDelay seconds... Exception: $($lastError.Exception.Message)"

            if ($OnRetry) {
                & $OnRetry $lastError.Exception $attempt
            }

            if ($currentDelay -gt 0) {
                Start-Sleep -Milliseconds ([int][Math]::Round($currentDelay * 1000))
            }
        }
    }
}
