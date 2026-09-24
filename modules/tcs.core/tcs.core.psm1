# Root folder of tcs.core, used by helpers that need files shipped with the module
$script:TcsCoreModuleRoot = $PSScriptRoot

#region load classes, then private and public functions
$ClassFiles = @(Get-ChildItem -Path (Join-Path -Path $PSScriptRoot -ChildPath 'Classes') -Filter '*.ps1' -Recurse -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -notlike '*.Tests.ps1' })
$Private = @(Get-ChildItem -Path (Join-Path -Path $PSScriptRoot -ChildPath 'Private') -Filter '*.ps1' -Recurse -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -notlike '*.Tests.ps1' })
$Public = @(Get-ChildItem -Path (Join-Path -Path $PSScriptRoot -ChildPath 'Public') -Filter '*.ps1' -Recurse -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -notlike '*.Tests.ps1' })

foreach ($File in @($ClassFiles + $Private + $Public)) {
    try {
        . $File.FullName
    }
    catch {
        Write-Error -Message "Failed to import '$($File.FullName)': $_"
    }
}
#endregion

#region module config and update check (never blocks import)
try {
    $CurrentConfig = Get-ModuleConfig -CommandPath $PSCommandPath -ErrorAction Stop
    if ($CurrentConfig.UpdateWarning -eq $true) {
        $null = Get-ModuleStatus -ShowMessage -ModuleName $CurrentConfig.ModuleName -ModulePath $CurrentConfig.ModulePath -CacheHours $CurrentConfig.UpdateCheckIntervalHours
    }
}
catch {
    Write-Warning "tcs.core configuration could not be loaded; defaults will be used. $($_.Exception.Message)"
}
#endregion

#region clean up when the module is removed
$ExecutionContext.SessionState.Module.OnRemove = {
    if ($script:TelemetryHttpClient) {
        $script:TelemetryHttpClient.Dispose()
        $script:TelemetryHttpClient = $null
    }
}
#endregion

Export-ModuleMember -Function $Public.BaseName
