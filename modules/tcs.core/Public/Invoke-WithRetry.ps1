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
    The base delay in seconds between retry attempts. Defaults to 2.

.PARAMETER BackoffMultiplier
    A multiplier applied to the delay on each successive retry. Set to a value greater
    than 1 for exponential backoff (e.g., 2 doubles the delay each retry). Defaults to 1
    (constant delay).

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

.NOTES
    Author: Nigel Tatschner
    Company: TheCodeSaiyan
    Version: 0.2.0

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
        [int]$MaxRetries = 3,

        [Parameter(HelpMessage = "Base delay in seconds between retries.")]
        [int]$DelaySeconds = 2,

        [Parameter(HelpMessage = "Multiplier applied to the delay on each successive retry.")]
        [double]$BackoffMultiplier = 1,

        [Parameter(HelpMessage = "Optional list of exception types to retry on.")]
        [type[]]$RetryableExceptions,

        [Parameter(HelpMessage = "Optional callback script block invoked on each retry.")]
        [scriptblock]$OnRetry
    )

    $attempt = 0
    $lastException = $null

    while ($true) {
        try {
            $result = & $ScriptBlock
            return $result
        }
        catch {
            $lastException = $_.Exception
            $attempt++

            # Check if we should retry based on exception type
            if ($RetryableExceptions) {
                $shouldRetry = $false
                foreach ($exType in $RetryableExceptions) {
                    if ($lastException -is $exType) {
                        $shouldRetry = $true
                        break
                    }
                }
                if (-not $shouldRetry) {
                    throw
                }
            }

            if ($attempt -gt $MaxRetries) {
                throw $lastException
            }

            $currentDelay = $DelaySeconds * [Math]::Pow($BackoffMultiplier, $attempt)

            Write-Verbose "Attempt $attempt of $MaxRetries failed. Retrying in $currentDelay seconds... Exception: $($lastException.Message)"

            if ($OnRetry) {
                & $OnRetry $lastException $attempt
            }

            Start-Sleep -Seconds $currentDelay
        }
    }
}
