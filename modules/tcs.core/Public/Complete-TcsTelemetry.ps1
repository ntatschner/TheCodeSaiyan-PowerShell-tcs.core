<#
.SYNOPSIS
    Completes a run started with Start-TcsTelemetry and sends its telemetry event.

.DESCRIPTION
    The Complete-TcsTelemetry function stops the timer for a token from Start-TcsTelemetry and
    sends one event (success or failure, duration, and the exception type on failure). Call it
    at the end of the command, normally in the end block.

    The run is reported as failed when -Failed or -ErrorRecord is given, or when
    Invoke-TcsCommand -Token saw an error during the run.

    A token is completed only once; later calls do nothing. Tokens of nested runs
    (IsOutermost = $false) send nothing. Telemetry never breaks the caller: errors are written
    to the verbose stream only, and nothing is written to the pipeline.

.PARAMETER Token
    The token returned by Start-TcsTelemetry.

.PARAMETER ErrorRecord
    The error that ended the run (an ErrorRecord or Exception). The run is reported as failed
    and only the exception type name is sent.

.PARAMETER Failed
    Reports the run as failed.

.INPUTS
    Tcs.TelemetryToken
    You can pipe a token to Complete-TcsTelemetry.

.OUTPUTS
    None

.EXAMPLE
    end {
        Complete-TcsTelemetry -Token $telemetry -Failed:($failures -gt 0)
    }

    Completes the run, as failed when the command counted failures itself.

.EXAMPLE
    catch {
        Complete-TcsTelemetry -Token $telemetry -ErrorRecord $_
        throw
    }

    Reports the caught error's type and rethrows it.

.NOTES
    Author: Nigel Tatschner
    Company: TheCodeSaiyan

.LINK
    Start-TcsTelemetry

.LINK
    Invoke-TcsCommand
#>
function Complete-TcsTelemetry {
    [CmdletBinding()]
    [OutputType([void])]
    param(
        [Parameter(Mandatory, ValueFromPipeline, HelpMessage = 'Token returned by Start-TcsTelemetry.')]
        [PSTypeName('Tcs.TelemetryToken')]
        [PSCustomObject]$Token,

        [Parameter(HelpMessage = 'The error that ended the run.')]
        [AllowNull()]
        [object]$ErrorRecord,

        [Parameter(HelpMessage = 'Report the run as failed.')]
        [switch]$Failed
    )

    process {
        try {
            if ($Failed -or $null -ne $ErrorRecord) {
                Set-TcsTelemetryFailure -Token $Token -ErrorRecord $ErrorRecord
            }
            Complete-TcsTelemetryToken -Token $Token
        }
        catch {
            Write-Verbose "Telemetry could not be completed: $($_.Exception.Message)"
        }
    }
}
