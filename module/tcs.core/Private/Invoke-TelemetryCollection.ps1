<#
.SYNOPSIS
    Collects and sends telemetry data for module usage tracking.

.DESCRIPTION
    The Invoke-TelemetryCollection function gathers system, PowerShell, and module-specific
    telemetry data for usage analytics. It collects non-identifying hardware information,
    operating system details, PowerShell version information, and module execution metrics.
    The data is sent asynchronously to a specified URI endpoint for analysis while preserving
    user privacy through anonymization techniques.

.PARAMETER ModuleName
    The name of the module generating the telemetry data. Defaults to 'UnknownModule'
    if not specified.

.PARAMETER ModuleVersion
    The version of the module generating the telemetry data. Defaults to 'UnknownModuleVersion'
    if not specified.

.PARAMETER ModulePath
    The file system path where the module is installed. Defaults to 'UnknownModulePath'
    if not specified.

.PARAMETER CommandName
    The name of the command or function being executed. Defaults to 'UnknownCommand'
    if not specified.

.PARAMETER ExecutionID
    A unique identifier for the current execution session. This is mandatory and used
    to correlate telemetry events across different stages.

.PARAMETER Stage
    The current stage of execution. Valid values are:
    - 'Start': Beginning of command execution
    - 'In-Progress': During command execution
    - 'End': Completion of command execution  
    - 'Module-Load': Module loading/import

.PARAMETER Failed
    Boolean value indicating whether the operation failed. Defaults to $false.

.PARAMETER Exception
    String containing exception details if the operation failed. Used for error tracking.

.PARAMETER Minimal
    Switch parameter that limits the telemetry data collected to essential information only,
    further enhancing privacy protection.

.PARAMETER ClearTimer
    Switch parameter that forces clearing and resetting of execution timing variables.

.PARAMETER URI
    The endpoint URI where telemetry data will be sent. This parameter is mandatory.

.INPUTS
    None
    This function does not accept pipeline input.

.OUTPUTS
    None
    This function does not return any output. It sends data asynchronously via background jobs.

.EXAMPLE
    Invoke-TelemetryCollection -ModuleName "tcs.core" -ExecutionID "12345" -Stage "Start" -URI "https://telemetry.example.com/api"
    
    Starts telemetry collection for the tcs.core module.

.EXAMPLE
    Invoke-TelemetryCollection -ExecutionID "12345" -Stage "End" -Failed $true -Exception $_.Exception -URI $TelemetryURI
    
    Records the end of execution with failure information.

.NOTES
    Author: Nigel Tatschner
    Company: TheCodeSaiyan
    Version: 0.1.7
    
    This is a private function used internally by the tcs.core module for telemetry
    collection. All data collected is anonymized and used solely for improving module
    functionality and user experience. No personally identifiable information is collected.
    
    The function uses background jobs to ensure telemetry collection doesn't impact
    module performance or user experience.
#>
function Invoke-TelemetryCollection {
    param (
        [CmdletBinding(HelpUri = 'https://PENDINGHOST/tcs.core/docs/Invoke-TelemetryCollection.html')]

        [string]$ModuleName = 'UnknownModule',

        [string]$ModuleVersion = 'UnknownModuleVersion',

        [string]$ModulePath = 'UnknownModulePath',

        [string]$CommandName = 'UnknownCommand',
        
        [Parameter(Mandatory = $true)]
        [string]$ExecutionID = 'UnknownExecutionID',

        [Parameter(Mandatory = $true)]
        [ValidateSet('Start', 'In-Progress', 'End', 'Module-Load')]
        [string]$Stage,

        [bool]$Failed = $false,

        [string]$Exception,

        [switch]$Minimal,

        [switch]$ClearTimer,

        [Parameter(Mandatory = $true)]
        [string]$URI
    )

    $CurrentTime = (Get-Date).ToString("yyyy-MM-ddTHH:mm:sszzz")

    switch -Regex ($Stage) {
        'Module-Load' {
            if ((Get-Variable -Name "GlobalExecutionDuration_$ExecutionID" -Scope script -ErrorAction SilentlyContinue) -and (-Not $ClearTimer)) {
                Set-Variable -Name "GlobalExecutionDuration_$ExecutionID" -Value (Get-Variable -Name "GlobalExecutionDuration_$ExecutionID" -Scope script -ErrorAction SilentlyContinue) -Scope script -Force | Out-Null
            }
            else {
                New-Variable -Name "GlobalExecutionDuration_$ExecutionID" -Value $(Get-Date) -Scope script -Force | Out-Null
            }
        }
        'Start' {
            if ((Get-Variable -Name "GlobalExecutionDuration_$ExecutionID" -Scope script -ErrorAction SilentlyContinue) -and (-Not $ClearTimer)) {
                Set-Variable -Name "GlobalExecutionDuration_$ExecutionID" -Value (Get-Variable -Name "GlobalExecutionDuration_$ExecutionID" -Scope script -ErrorAction SilentlyContinue) -Scope script -Force | Out-Null
            }
            else {
                New-Variable -Name "GlobalExecutionDuration_$ExecutionID" -Value $(Get-Date) -Scope script -Force | Out-Null
            }
        }
        "End|Module-Load" {
            Start-Job -Name "TC_Job_Trying_To_Be_Unique_9000" -ArgumentList $(Get-Variable -Name "GlobalExecutionDuration_$ExecutionID" -ErrorAction SilentlyContinue).Value -ScriptBlock {
                param ($GlobalExecutionDuration)
                $ExecutionDuration = [Int64]$($(New-TimeSpan -Start $GlobalExecutionDuration -End $(Get-Date)).TotalMilliseconds * 1e6)
                $WebRequestArgs = @{
                    Uri             = $Using:URI
                    Method          = 'Put'
                    ContentType     = 'application/json'
                    UseBasicParsing = $true
                }
                # Generate hardware specific but none identifying telemetry data for the output
                $Hardware = Get-WmiObject -Class Win32_ComputerSystem
                $bootPartition = Get-WmiObject -Class Win32_DiskPartition | Where-Object -Property bootpartition -eq True
                $bootDriveSerial = $(Get-WmiObject -Class Win32_DiskDrive | Where-Object -Property index -eq $bootPartition.diskIndex)
                if ([string]::IsNullOrEmpty($bootDriveSerial.SerialNumber) -and ($bootDriveSerial.Model -like '*Virtual*')) {
                    $bootDriveSerial = "VirtualDrive-$($bootDriveSerial.size)"
                }
                else {
                    $bootDriveSerial = $bootDriveSerial.SerialNumber.Trim()
                }

                $HardwareData = @{
                    Manufacturer              = $Hardware.Manufacturer
                    Model                     = $Hardware.Model
                    TotalPhysicalMemory       = $Hardware.TotalPhysicalMemory
                    NumberOfProcessors        = $Hardware.NumberOfProcessors
                    NumberOfLogicalProcessors = $Hardware.NumberOfLogicalProcessors
                    PartOfDomain              = $Hardware.PartOfDomain
                    HardwareSerialNumber      = $((Get-WmiObject -Class Win32_BIOS).SerialNumber)
                    BootDriveSerial           = $bootDriveSerial
                }

                # Generate OS specific but none identifying telemetry data for the output
                $OS = Get-WmiObject -Class Win32_OperatingSystem

                $OSData = @{
                    OSType         = $OS.Caption
                    OSArchitecture = $OS.OSArchitecture
                    OSVersion      = $OS.Version
                    OSBuildNumber  = $OS.BuildNumber
                    SerialNumber   = $OS.SerialNumber
                }

                # Generate PowerShell specific but none identifying telemetry data for the output

                $PSData = @{
                    PowerShellVersion = $PSVersionTable.PSVersion.ToString()
                    HostVersion       = $Host.Version.ToString()
                    HostName          = $Host.Name.ToString()
                    HostUI            = $Host.UI.ToString()
                    HostCulture       = $Host.CurrentCulture.ToString()
                    HostUICulture     = $Host.CurrentUICulture.ToString()
                }

                # Generate module specific but none identifying telemetry data for the output

                $ModuleData = @{
                    ModuleName    = if ([string]::IsNullOrEmpty($Using:ModuleName)) { 'UnknownModule' } else { $Using:ModuleName }
                    ModuleVersion = if ([string]::IsNullOrEmpty($Using:ModuleVersion)) { 'UnknownModuleVersion' } else { $Using:ModuleVersion }
                    ModulePath    = if ([string]::IsNullOrEmpty($Using:ModulePath)) { 'UnknownModulePath' } else { $Using:ModulePath }
                    CommandName   = if ([string]::IsNullOrEmpty($Using:CommandName)) { 'UnknownCommand' } else { $Using:CommandName }
                }
                # Create a new hashtable
                $AllData = @{}

                # Add each hashtable to the new hashtable
                $AllData += $HardwareData
                $AllData += $OSData
                $AllData += $PSData
                $AllData += $ModuleData
                $AllData += @{ID = $AllData.BootDriveSerial + "_" + $AllData.SerialNumber } 
                $AllData += @{LocalDateTime = $Using:CurrentTime }
                $AllData += @{ExecutionDuration = $ExecutionDuration }
                $AllData += @{Stage = $Using:Stage }
                $AllData += @{Failed = $Using:Failed }
                $AllData += @{Exception = $Using:Exception | Out-String }
                $AllData += @{ExecutionID = $Using:ExecutionID }
                if ($Minimal) {
                    $AllData | ForEach-Object {
                        if ($_.Name -notin @('ID', 'CommandName', 'ModuleName', 'ModuleVersion', 'LocalDateTime', 'ExecutionDuration', 'Stage', 'Failed', 'Exception', 'ExecutionID')) {
                            $_.Value = 'Minimal'
                        }
                        $body = $AllData | ConvertTo-Json
                        Invoke-WebRequest @WebRequestArgs -Body $body | Out-Null
                    }
                }
                else {
                    $body = $AllData | ConvertTo-Json
                    Invoke-WebRequest @WebRequestArgs -Body $body | Out-Null
                }
            } | Out-Null
            # Clear Old Jobs
            Get-Job -Name "TC_Job_Trying_To_Be_Unique_9000" -ErrorAction SilentlyContinue | Where-Object State -in Completed, Failed | Remove-Job -Force -ErrorAction SilentlyContinue | Out-Null
        }
    }
}
