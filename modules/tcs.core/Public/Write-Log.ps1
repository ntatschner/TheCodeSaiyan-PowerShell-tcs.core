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

.PARAMETER UseUtc
    Writes timestamps in UTC instead of local time.

.PARAMETER PassThru
    Returns the formatted log line.

.INPUTS
    System.String
    You can pipe one or more strings to Write-Log.

.OUTPUTS
    None, or System.String when PassThru is specified.

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

    File writes append with shared read/write access, so several processes can log to the
    same file. Files are written as UTF-8 without a byte order mark.

.LINK
    https://ntatschner.github.io/TheCodeSaiyan-PowerShell-tcs.core/
#>
function Write-Log {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingWriteHost', '',
        Justification = 'Coloured console output is the purpose of this function; Write-Host writes to the information stream (6) on PowerShell 5+.')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidOverwritingBuiltInCmdlets', '',
        Justification = 'Write-Log is not a built-in command in current PowerShell versions; the name is part of the public API.')]
    [CmdletBinding()]
    [OutputType([void], [string])]
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
        [ValidateNotNullOrEmpty()]
        [string]$DateFormat = 'yyyy-MM-dd HH:mm:ss',

        [Parameter(HelpMessage = "Write timestamps in UTC.")]
        [switch]$UseUtc,

        [Parameter(HelpMessage = "Return the formatted log line.")]
        [switch]$PassThru
    )

    process {
        $now = if ($UseUtc) { [datetime]::UtcNow } else { [datetime]::Now }
        $timestamp = $now.ToString($DateFormat, [System.Globalization.CultureInfo]::InvariantCulture)

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
            $utf8NoBom = New-Object System.Text.UTF8Encoding -ArgumentList $false
            $bytes = $utf8NoBom.GetBytes($formattedMessage + [Environment]::NewLine)
            $resolvedLogPath = $PSCmdlet.GetUnresolvedProviderPathFromPSPath($LogPath)
            $stream = New-Object System.IO.FileStream -ArgumentList $resolvedLogPath, ([System.IO.FileMode]::Append), ([System.IO.FileAccess]::Write), ([System.IO.FileShare]::ReadWrite)
            try {
                $stream.Write($bytes, 0, $bytes.Length)
            }
            finally {
                $stream.Dispose()
            }
        }

        if ($PassThru) {
            $formattedMessage
        }
    }
}
