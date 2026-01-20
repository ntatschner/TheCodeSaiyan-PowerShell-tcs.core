#region get public and private function definition files.
$Public  = @(
    Get-ChildItem -Path $PSScriptRoot\Public\*.ps1 -Exclude "*.Tests.ps1" -ErrorAction SilentlyContinue
)
$Private = @(
    Get-ChildItem -Path $PSScriptRoot\Private\*.ps1 -Exclude "*.Tests.ps1" -ErrorAction SilentlyContinue
)
#endregion

#region source the files
foreach ($Function in @($Public + $Private)) {
    $FunctionPath = $Function.fullname
    try {
	. $FunctionPath # dot source function
    } catch {
	Write-Error -Message "Failed to import function at $($FunctionPath): $_"
    }
}
#endregion
# Module Config setup and import
try {
    $CurrentConfig = Get-ModuleConfig -CommandPath $PSCommandPath -ErrorAction Stop
}
catch {
    Write-Error "Module Import error: `n $($_.Exception.Message)"
}

if ($CurrentConfig.UpdateWarning -eq 'True') {
    Get-ModuleStatus -ShowMessage -ModuleName $CurrentConfig.ModuleName -ModulePath $CurrentConfig.ModulePath
}
#endregion

#region export Public functions ($Public.BaseName) for WIP modules
Export-ModuleMember -Function $Public.Basename
Export-ModuleMember -Function Invoke-TelemetryCollection, Get-ModuleConfig, Get-ModuleStatus, Get-ParameterValues
#endregion
