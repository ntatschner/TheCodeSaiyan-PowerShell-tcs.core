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

# Settings read from disk for modules that have not called Get-ModuleConfig in this session
$script:TelemetryConfigCache = @{}

function Get-TelemetryModuleConfig {
    <#
    .SYNOPSIS
        Returns the settings that decide whether and where a module sends telemetry.

    .DESCRIPTION
        Uses the session configuration loaded by Get-ModuleConfig when there is one. Otherwise
        reads the module's settings file (<config root>/<ModuleName>/Module.Config.json) over the
        tcs.core defaults, so a module's Telemetry = $false is honoured even when the module
        never called Get-ModuleConfig. The module path is not needed.
    #>
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [Parameter(Mandatory)]
        [string]$ModuleName
    )

    $config = $script:ModuleConfigCache[$ModuleName]
    if ($config) {
        return $config
    }
    if ($script:TelemetryConfigCache.ContainsKey($ModuleName)) {
        return $script:TelemetryConfigCache[$ModuleName]
    }

    $config = Get-DefaultModuleConfig
    if (Test-ModuleNameValid -Name $ModuleName) {
        $configFile = Join-Path -Path (Join-Path -Path (Get-ModuleConfigRoot) -ChildPath $ModuleName) -ChildPath 'Module.Config.json'
        if (Test-Path -LiteralPath $configFile) {
            try {
                $stored = Read-JsonFileAsHashtable -Path $configFile
                foreach ($key in $stored.Keys) {
                    $config[$key] = ConvertTo-ConfigValueType -Value $stored[$key] -DefaultValue $config[$key] -Key $key
                }
            }
            catch {
                Write-Verbose "Could not read '$configFile' for telemetry settings: $($_.Exception.Message)"
            }
        }
    }

    if ($script:TelemetryConfigCache.Count -gt 100) {
        $script:TelemetryConfigCache.Clear()
    }
    $script:TelemetryConfigCache[$ModuleName] = $config
    return $config
}

function Resolve-TelemetryApiKey {
    <#
    .SYNOPSIS
        Returns the telemetry API key in plain text. Values stored with Protect-ConfigValue
        ('tcs:v1:...') are decrypted; plain-text values written by tcs.core 0.3.0 are used as they are.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [AllowNull()]
        [AllowEmptyString()]
        [string]$Value
    )

    if ([string]::IsNullOrEmpty($Value) -or -not $Value.StartsWith("$($script:ProtectedValuePrefix):")) {
        return $Value
    }
    return (Unprotect-ConfigValue -EncryptedValue $Value -ErrorAction Stop)
}

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
