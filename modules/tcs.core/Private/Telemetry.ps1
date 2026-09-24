<#
.SYNOPSIS
    Internal helpers for Invoke-TelemetryCollection.

.NOTES
    Private helpers for the tcs.core module.
#>

# Stopwatches for in-flight commands, keyed by ExecutionID
$script:TelemetryTimers = @{}
$script:TelemetryHttpClient = $null
$script:TelemetryInstallationId = $null

function Test-TelemetryOptOut {
    [CmdletBinding()]
    [OutputType([bool])]
    param()

    return ([string]$env:TCS_TELEMETRY_OPTOUT -in @('1', 'true', 'yes'))
}

function Get-TelemetryInstallationId {
    <#
    .SYNOPSIS
        Returns a random, anonymous ID for this user profile, created on first use.
        It is not derived from any hardware, user or machine identifier.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param()

    if ($script:TelemetryInstallationId) {
        return $script:TelemetryInstallationId
    }

    $idPath = Join-Path -Path (Join-Path -Path (Get-ModuleConfigRoot) -ChildPath 'tcs.core') -ChildPath 'Telemetry.json'
    $id = $null
    try {
        if (Test-Path -LiteralPath $idPath) {
            $id = [string](Read-JsonFileAsHashtable -Path $idPath)['InstallationId']
        }
        if ([string]::IsNullOrWhiteSpace($id)) {
            $id = [guid]::NewGuid().ToString()
            Write-JsonFile -Path $idPath -Data @{ InstallationId = $id }
        }
    }
    catch {
        # Fall back to a per-session ID if the profile is not writable
        if ([string]::IsNullOrWhiteSpace($id)) {
            $id = [guid]::NewGuid().ToString()
        }
        Write-Verbose "Using a per-session telemetry ID: $($_.Exception.Message)"
    }

    $script:TelemetryInstallationId = $id
    return $id
}

function Get-TelemetryPlatform {
    [CmdletBinding()]
    [OutputType([string])]
    param()

    if (Test-IsWindowsPlatform) { return 'Windows' }
    if ($IsMacOS) { return 'macOS' }
    if ($IsLinux) { return 'Linux' }
    return 'Unknown'
}

function Send-TelemetryPayload {
    <#
    .SYNOPSIS
        Posts a JSON payload without waiting for the response (fire and forget).
    #>
    [CmdletBinding()]
    [OutputType([void])]
    param(
        [Parameter(Mandatory)]
        [string]$Uri,

        [string]$ApiKey,

        [Parameter(Mandatory)]
        [string]$Body
    )

    if (-not $script:TelemetryHttpClient) {
        if (-not ('System.Net.Http.HttpClient' -as [type])) {
            Add-Type -AssemblyName System.Net.Http
        }
        if ($PSVersionTable.PSEdition -eq 'Desktop') {
            # .NET Framework may not enable TLS 1.2 by default; add it without removing anything
            [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor [System.Net.SecurityProtocolType]::Tls12
        }
        $client = New-Object System.Net.Http.HttpClient
        $client.Timeout = [TimeSpan]::FromSeconds(5)
        $script:TelemetryHttpClient = $client
    }

    $request = New-Object System.Net.Http.HttpRequestMessage -ArgumentList ([System.Net.Http.HttpMethod]::Post), $Uri
    if (-not [string]::IsNullOrEmpty($ApiKey)) {
        $null = $request.Headers.TryAddWithoutValidation('X-API-Key', $ApiKey)
    }
    $request.Content = New-Object System.Net.Http.StringContent -ArgumentList $Body, ([System.Text.Encoding]::UTF8), 'application/json'

    # The request runs on the thread pool; the caller never waits and failures are ignored
    $null = $script:TelemetryHttpClient.SendAsync($request)
}
