<#
.SYNOPSIS
    Records anonymous usage telemetry for a command or module load.

.DESCRIPTION
    The Invoke-TelemetryCollection function times a command and sends one anonymous event to
    the tcs-telemetry ingestion API (POST, JSON, X-API-Key header) when the command ends or a
    module loads. Sending is asynchronous and never blocks or fails the caller.

    Data sent:
      timestamp (UTC), command_name, module_name, version, duration_ms, success,
      error_type (exception type name only, never the message), ps_version, os_platform,
      host_name (a random installation ID, not the machine name) and tags
      (stage, ps_edition, ps_host, plus any -Tags given).
    No user name, machine name, path, hardware identifier or error text is sent.

    Nothing is sent when:
      - the TCS_TELEMETRY_OPTOUT environment variable is 1, true or yes;
      - the module's Telemetry setting is $false (Set-ModuleConfig -Telemetry $false);
      - no endpoint is configured (-URI, TCS_TELEMETRY_URI, or the TelemetryUri setting);
      - the endpoint is not HTTPS (http://localhost is allowed for testing).

    Stages:
      Start        starts the timer for ExecutionID (nothing is sent)
      In-Progress  no action (kept for compatibility)
      End          stops the timer and sends the event
      Module-Load  sends an event with a duration of 0

.PARAMETER ModuleName
    The name of the module sending telemetry. Its settings (from Get-ModuleConfig) decide
    whether telemetry is on and which endpoint is used.

.PARAMETER ModuleVersion
    The version of the module.

.PARAMETER CommandName
    The name of the command being run.

.PARAMETER ExecutionID
    A unique ID that links the Start and End stages of one command run.

.PARAMETER Stage
    Start, In-Progress, End or Module-Load.

.PARAMETER Failed
    Whether the command failed.

.PARAMETER Exception
    The error (ErrorRecord, Exception or string). Only its type name is sent.

.PARAMETER ClearTimer
    On Start, restarts the timer even if one is already running for ExecutionID.

.PARAMETER URI
    Overrides the ingestion endpoint, e.g. https://telemetry.example.com/ingest/powershell.

.PARAMETER ApiKey
    Overrides the API key sent in the X-API-Key header.

.PARAMETER Tags
    Extra low-cardinality tags to send with the event.

.PARAMETER ModulePath
    Deprecated and ignored. Paths are no longer sent because they can contain user names.

.PARAMETER Minimal
    Deprecated and ignored. All telemetry is now minimal.

.INPUTS
    None
    This function does not accept pipeline input.

.OUTPUTS
    None

.EXAMPLE
    $id = [guid]::NewGuid().ToString()
    Invoke-TelemetryCollection -ModuleName 'tcs.jira' -ModuleVersion '0.1.0' -CommandName 'Get-JiraTicket' -ExecutionID $id -Stage Start
    try {
        # command body
        Invoke-TelemetryCollection -ModuleName 'tcs.jira' -ModuleVersion '0.1.0' -CommandName 'Get-JiraTicket' -ExecutionID $id -Stage End
    }
    catch {
        Invoke-TelemetryCollection -ModuleName 'tcs.jira' -ModuleVersion '0.1.0' -CommandName 'Get-JiraTicket' -ExecutionID $id -Stage End -Failed $true -Exception $_
        throw
    }

    Times a command and reports success or failure.

.NOTES
    Author: Nigel Tatschner
    Company: TheCodeSaiyan
#>
function Invoke-TelemetryCollection {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', 'ModulePath',
        Justification = 'Deprecated parameter kept for backward compatibility.')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', 'Minimal',
        Justification = 'Deprecated parameter kept for backward compatibility.')]
    [CmdletBinding()]
    [OutputType([void])]
    param (
        [string]$ModuleName = 'UnknownModule',

        [string]$ModuleVersion = 'Unknown',

        [string]$CommandName = 'UnknownCommand',

        [Parameter(Mandatory = $true)]
        [string]$ExecutionID,

        [Parameter(Mandatory = $true)]
        [ValidateSet('Start', 'In-Progress', 'End', 'Module-Load')]
        [string]$Stage,

        [bool]$Failed = $false,

        [object]$Exception,

        [switch]$ClearTimer,

        [string]$URI,

        [string]$ApiKey,

        [hashtable]$Tags,

        # Deprecated and ignored; kept so existing callers keep working
        [string]$ModulePath,

        # Deprecated and ignored; kept so existing callers keep working
        [switch]$Minimal
    )

    # Telemetry must never break the caller
    try {
        if (Test-TelemetryOptOut) {
            return
        }

        $config = $script:ModuleConfigCache[$ModuleName]
        if (-not $config) {
            $config = Get-DefaultModuleConfig
        }
        if ($config['Telemetry'] -eq $false) {
            return
        }

        switch ($Stage) {
            'Start' {
                if ($ClearTimer -or -not $script:TelemetryTimers.ContainsKey($ExecutionID)) {
                    if ($script:TelemetryTimers.Count -gt 1000) {
                        # Guard against Start calls that never reach End
                        $script:TelemetryTimers.Clear()
                    }
                    $script:TelemetryTimers[$ExecutionID] = [System.Diagnostics.Stopwatch]::StartNew()
                }
                return
            }
            'In-Progress' {
                return
            }
        }

        $durationMs = [int64]0
        if ($Stage -eq 'End' -and $script:TelemetryTimers.ContainsKey($ExecutionID)) {
            $durationMs = [int64]$script:TelemetryTimers[$ExecutionID].ElapsedMilliseconds
            $script:TelemetryTimers.Remove($ExecutionID)
        }

        $endpoint = $URI
        if ([string]::IsNullOrWhiteSpace($endpoint)) { $endpoint = $env:TCS_TELEMETRY_URI }
        if ([string]::IsNullOrWhiteSpace($endpoint)) { $endpoint = [string]$config['TelemetryUri'] }
        if ([string]::IsNullOrWhiteSpace($endpoint)) {
            Write-Verbose 'Telemetry skipped: no endpoint configured.'
            return
        }
        if ($endpoint -notmatch '^https://' -and $endpoint -notmatch '^http://(localhost|127\.0\.0\.1)(:\d+)?/') {
            Write-Verbose 'Telemetry skipped: the endpoint must use HTTPS.'
            return
        }

        $key = $ApiKey
        if ([string]::IsNullOrEmpty($key)) { $key = $env:TCS_TELEMETRY_APIKEY }
        if ([string]::IsNullOrEmpty($key)) { $key = [string]$config['TelemetryApiKey'] }

        $errorType = $null
        if ($Failed -or $Exception) {
            $errorType = if ($Exception -is [System.Management.Automation.ErrorRecord]) {
                $Exception.Exception.GetType().FullName
            }
            elseif ($Exception -is [System.Exception]) {
                $Exception.GetType().FullName
            }
            else {
                'Unknown'
            }
        }

        $eventTags = @{
            stage      = $Stage
            ps_edition = [string]$PSVersionTable.PSEdition
            ps_host    = [string]$Host.Name
        }
        if ($Tags) {
            foreach ($tagKey in $Tags.Keys) {
                $eventTags[[string]$tagKey] = [string]$Tags[$tagKey]
            }
        }

        $payload = [ordered]@{
            timestamp    = [datetime]::UtcNow.ToString('yyyy-MM-ddTHH:mm:ss.fffZ', [System.Globalization.CultureInfo]::InvariantCulture)
            command_name = $CommandName
            module_name  = $ModuleName
            version      = [string]$ModuleVersion
            duration_ms  = $durationMs
            success      = -not $Failed
            host_name    = Get-TelemetryInstallationId
            ps_version   = $PSVersionTable.PSVersion.ToString()
            os_platform  = Get-TelemetryPlatform
            tags         = $eventTags
        }
        if ($errorType) {
            $payload['error_type'] = $errorType
        }

        Send-TelemetryPayload -Uri $endpoint -ApiKey $key -Body ($payload | ConvertTo-Json -Depth 3 -Compress)
    }
    catch {
        Write-Verbose "Telemetry skipped: $($_.Exception.Message)"
    }
}
