<#
.SYNOPSIS
    Checks whether a newer version of a module is available in the PowerShell Gallery.

.DESCRIPTION
    The Get-ModuleStatus function compares the installed version of a module with the latest
    version in the PowerShell Gallery and returns a status object.

    The gallery is queried at most once per CacheHours (default 24). The result is cached in
    <ApplicationData>/PowerShell/Config/<ModuleName>/UpdateCheck.json, so importing a module
    does not make a network call every time. Failed lookups (for example when offline) are
    cached too, so they are not retried on every import.

    The function never throws: if the check fails it writes a verbose message and returns a
    status object with LatestVersion set to $null.

    Set the TCS_SKIP_UPDATE_CHECK environment variable to 1 to turn the check off (for example
    in CI). -Force overrides this and the cache.

.PARAMETER ShowMessage
    Writes a warning when an update is available.

.PARAMETER ModuleName
    The name of the module as published in the PowerShell Gallery. Only letters, digits, '.',
    '_' and '-' are allowed.

.PARAMETER ModulePath
    The folder that contains the module manifest (<ModuleName>.psd1).

.PARAMETER CacheHours
    How long a gallery result is reused, in hours. 0 always queries the gallery.

.PARAMETER Force
    Queries the gallery now, ignoring the cache and TCS_SKIP_UPDATE_CHECK.

.INPUTS
    None
    This function does not accept pipeline input.

.OUTPUTS
    PSCustomObject
    ModuleName, CurrentVersion, LatestVersion, UpdateAvailable, CheckedAt (UTC) and Source
    ('Gallery', 'Cache' or 'Skipped').

.EXAMPLE
    Get-ModuleStatus -ModuleName 'tcs.core' -ModulePath (Get-Module tcs.core).ModuleBase -ShowMessage

    Warns if a newer tcs.core is available, using the cached result if it is less than a day old.

.EXAMPLE
    (Get-ModuleStatus -ModuleName 'tcs.jira' -ModulePath $path -Force).UpdateAvailable

    Queries the gallery now and returns whether an update is available.

.NOTES
    Author: Nigel Tatschner
    Company: TheCodeSaiyan

    Uses Find-PSResource (Microsoft.PowerShell.PSResourceGet) when available, otherwise
    Find-Module (PowerShellGet).
#>
function Get-ModuleStatus {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param (
        [switch]$ShowMessage,

        [ValidateNotNullOrEmpty()]
        [ValidatePattern('^[A-Za-z0-9][A-Za-z0-9._-]*$')]
        [Parameter(Mandatory)]
        [string]$ModuleName,

        [ValidateNotNullOrEmpty()]
        [Parameter(Mandatory)]
        [string]$ModulePath,

        [ValidateRange(0, 8760)]
        [int]$CacheHours = 24,

        [switch]$Force
    )

    $status = [PSCustomObject]@{
        ModuleName      = $ModuleName
        CurrentVersion  = $null
        LatestVersion   = $null
        UpdateAvailable = $false
        CheckedAt       = $null
        Source          = 'Skipped'
    }

    try {
        $manifestPath = Join-Path -Path $ModulePath -ChildPath "$ModuleName.psd1"
        $status.CurrentVersion = [version](Import-PowerShellDataFile -LiteralPath $manifestPath).ModuleVersion

        if (-not $Force -and $env:TCS_SKIP_UPDATE_CHECK -in @('1', 'true', 'yes')) {
            return $status
        }

        $cachePath = Join-Path -Path (Join-Path -Path (Get-ModuleConfigRoot) -ChildPath $ModuleName) -ChildPath 'UpdateCheck.json'
        $cache = $null
        if (-not $Force -and $CacheHours -gt 0 -and (Test-Path -LiteralPath $cachePath)) {
            try {
                $cache = Read-JsonFileAsHashtable -Path $cachePath
            }
            catch {
                Write-Verbose "Ignoring unreadable update cache '$cachePath': $($_.Exception.Message)"
            }
        }

        $lastChecked = $null
        if ($cache -and $cache['LastChecked']) {
            # PowerShell 7 turns ISO dates into DateTime; Windows PowerShell leaves them as strings
            $lastChecked = if ($cache['LastChecked'] -is [datetime]) {
                $cache['LastChecked'].ToUniversalTime()
            }
            else {
                [datetime]::Parse($cache['LastChecked'], [System.Globalization.CultureInfo]::InvariantCulture, [System.Globalization.DateTimeStyles]::AdjustToUniversal -bor [System.Globalization.DateTimeStyles]::AssumeUniversal)
            }
        }

        if ($lastChecked -and ([datetime]::UtcNow - $lastChecked).TotalHours -lt $CacheHours) {
            $status.Source = 'Cache'
            $status.CheckedAt = $lastChecked
            if ($cache['LatestVersion']) {
                $status.LatestVersion = [version]$cache['LatestVersion']
            }
        }
        else {
            $status.Source = 'Gallery'
            $status.CheckedAt = [datetime]::UtcNow
            try {
                # Lookup errors are collected, never shown: a missing or offline gallery must not print errors on import
                $lookupErrors = $null
                if (Get-Command -Name Find-PSResource -ErrorAction SilentlyContinue) {
                    $found = Find-PSResource -Name $ModuleName -ErrorAction SilentlyContinue -ErrorVariable lookupErrors -WarningAction SilentlyContinue -Verbose:$false 2>$null
                }
                else {
                    $found = Find-Module -Name $ModuleName -ErrorAction SilentlyContinue -ErrorVariable lookupErrors -WarningAction SilentlyContinue -Verbose:$false 2>$null
                }
                $status.LatestVersion = $found | ForEach-Object { [version]([string]$_.Version -replace '-.*$', '') } |
                    Sort-Object -Descending | Select-Object -First 1
                if (-not $status.LatestVersion -and $lookupErrors) {
                    Write-Verbose "Update check for '$ModuleName' failed: $($lookupErrors[0])"
                }
            }
            catch {
                Write-Verbose "Update check for '$ModuleName' failed: $($_.Exception.Message)"
            }

            try {
                $versionText = if ($status.LatestVersion) { $status.LatestVersion.ToString() } else { $null }
                Write-JsonFile -Path $cachePath -Data @{
                    LastChecked   = $status.CheckedAt.ToString('o')
                    LatestVersion = $versionText
                }
            }
            catch {
                Write-Verbose "Could not write update cache '$cachePath': $($_.Exception.Message)"
            }
        }

        $status.UpdateAvailable = [bool]($status.LatestVersion -and $status.CurrentVersion -lt $status.LatestVersion)
        if ($ShowMessage -and $status.UpdateAvailable) {
            Write-Warning "An update is available for '$ModuleName'. Installed: $($status.CurrentVersion), latest: $($status.LatestVersion). Run 'Update-Module $ModuleName' (or 'Update-PSResource $ModuleName') to update."
        }
    }
    catch {
        Write-Verbose "Get-ModuleStatus failed for '$ModuleName': $($_.Exception.Message)"
    }

    return $status
}
