<#
.SYNOPSIS
    Writes a structured log message to the console and/or a log file.

.DESCRIPTION
    The Write-Log function provides structured logging with severity levels, timestamps,
    and optional component prefixes. Messages can be written to the console with color-coded
    output, to a log file, or both. The function supports pipeline input for batch logging
    and uses appropriate PowerShell output streams for Debug and Verbose levels.

.PARAMETER Message
    The log message to write. Accepts pipeline input, allowing multiple messages to be
    logged in sequence.

.PARAMETER Level
    The severity level of the log message. Valid values are 'Info', 'Warning', 'Error',
    'Debug', and 'Verbose'. Defaults to 'Info'. Debug and Verbose levels use their
    respective PowerShell output streams (Write-Debug, Write-Verbose) for console output.

.PARAMETER LogPath
    An optional file path to append the formatted log message to. If the file or its parent
    directory does not exist, they will be created automatically.

.PARAMETER Component
    An optional component or module name prefix included in the formatted log message.
    When specified, the message is formatted as [$timestamp][$Level][$Component] $Message.

.PARAMETER NoConsole
    When specified, suppresses console output and only writes to the log file. Requires
    LogPath to be specified for any output to occur.

.PARAMETER DateFormat
    The timestamp format string used for log entries. Defaults to 'yyyy-MM-dd HH:mm:ss'.
    Accepts any valid .NET DateTime format string.

.INPUTS
    System.String
    You can pipe one or more strings to Write-Log.

.OUTPUTS
    None
    This function does not produce pipeline output.

.EXAMPLE
    Write-Log -Message "Application started successfully."

    Writes an Info-level message to the console with a timestamp.

.EXAMPLE
    Write-Log -Message "Connection failed" -Level Error -Component "Network" -LogPath "C:\Logs\app.log"

    Writes an Error-level message with a component prefix to both the console (in red) and
    the specified log file.

.EXAMPLE
    "Step 1 complete", "Step 2 complete" | Write-Log -Level Info -LogPath "C:\Logs\steps.log" -NoConsole

    Pipes multiple messages to be logged silently to a file without console output.

.NOTES
    Author: Nigel Tatschner
    Company: TheCodeSaiyan
    Version: 0.2.0

    This function is part of the tcs.core module and provides a lightweight structured
    logging mechanism suitable for scripts and module development.

.LINK
    https://ntatschner.github.io/TheCodeSaiyan-PowerShell-tcs.core/
#>
function Write-Log {
    [CmdletBinding()]
    [OutputType([void])]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, Position = 0, HelpMessage = "The log message to write.")]
        [string]$Message,

        [Parameter(HelpMessage = "The severity level of the log message.")]
        [ValidateSet('Info', 'Warning', 'Error', 'Debug', 'Verbose')]
        [string]$Level = 'Info',

        [Parameter(HelpMessage = "File path to append the log message to.")]
        [string]$LogPath,

        [Parameter(HelpMessage = "Optional component or module name prefix.")]
        [string]$Component,

        [Parameter(HelpMessage = "Suppress console output and only write to file.")]
        [switch]$NoConsole,

        [Parameter(HelpMessage = "Timestamp format string for log entries.")]
        [string]$DateFormat = 'yyyy-MM-dd HH:mm:ss'
    )

    process {
        $timestamp = Get-Date -Format $DateFormat

        if ([string]::IsNullOrWhiteSpace($Component)) {
            $formattedMessage = "[$timestamp][$Level] $Message"
        }
        else {
            $formattedMessage = "[$timestamp][$Level][$Component] $Message"
        }

        if (-not $NoConsole) {
            switch ($Level) {
                'Info' {
                    Write-Host $formattedMessage -ForegroundColor Cyan
                }
                'Warning' {
                    Write-Host $formattedMessage -ForegroundColor Yellow
                }
                'Error' {
                    Write-Host $formattedMessage -ForegroundColor Red
                }
                'Debug' {
                    Write-Debug $formattedMessage
                }
                'Verbose' {
                    Write-Verbose $formattedMessage
                }
            }
        }

        if ($LogPath) {
            $logDirectory = Split-Path -Path $LogPath -Parent
            if ($logDirectory -and -not (Test-Path -Path $logDirectory)) {
                New-Item -Path $logDirectory -ItemType Directory -Force | Out-Null
            }
            Add-Content -Path $LogPath -Value $formattedMessage -Encoding UTF8
        }
    }
}
