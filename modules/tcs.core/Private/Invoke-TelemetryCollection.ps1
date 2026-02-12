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
    [CmdletBinding(HelpUri = 'https://ntatschner.github.io/TheCodeSaiyan-PowerShell-tcs.core/')]
    param (
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

    # Validate URI uses HTTPS to prevent sending telemetry over insecure channels
    if ($URI -notmatch '^https://') {
        Write-Warning "Telemetry URI must use HTTPS. Telemetry collection skipped."
        return
    }

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

                # Enforce TLS 1.2+
                [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

                $ExecutionDuration = [Int64]$($(New-TimeSpan -Start $GlobalExecutionDuration -End $(Get-Date)).TotalMilliseconds * 1e6)
                $WebRequestArgs = @{
                    Uri             = $Using:URI
                    Method          = 'Put'
                    ContentType     = 'application/json'
                    UseBasicParsing = $true
                }

                # Helper to hash sensitive identifiers before transmission
                function Get-HashedValue {
                    param([string]$Value)
                    if ([string]::IsNullOrEmpty($Value)) { return 'Unknown' }
                    $sha256 = [System.Security.Cryptography.SHA256]::Create()
                    $bytes = [System.Text.Encoding]::UTF8.GetBytes($Value)
                    $hash = $sha256.ComputeHash($bytes)
                    return [BitConverter]::ToString($hash).Replace('-', '').Substring(0, 16)
                }

                # Generate hardware telemetry using CIM (cross-edition compatible)
                $Hardware = Get-CimInstance -ClassName Win32_ComputerSystem
                $BIOS = Get-CimInstance -ClassName Win32_BIOS
                $bootPartition = Get-CimInstance -ClassName Win32_DiskPartition | Where-Object { $_.BootPartition -eq $true }
                $bootDrive = Get-CimInstance -ClassName Win32_DiskDrive | Where-Object { $_.Index -eq $bootPartition.DiskIndex }
                if ([string]::IsNullOrEmpty($bootDrive.SerialNumber) -and ($bootDrive.Model -like '*Virtual*')) {
                    $bootDriveSerial = Get-HashedValue "VirtualDrive-$($bootDrive.Size)"
                }
                else {
                    $bootDriveSerial = Get-HashedValue $bootDrive.SerialNumber.Trim()
                }

                $HardwareData = @{
                    Manufacturer              = $Hardware.Manufacturer
                    Model                     = $Hardware.Model
                    TotalPhysicalMemory       = $Hardware.TotalPhysicalMemory
                    NumberOfProcessors        = $Hardware.NumberOfProcessors
                    NumberOfLogicalProcessors = $Hardware.NumberOfLogicalProcessors
                    PartOfDomain              = $Hardware.PartOfDomain
                    HardwareSerialNumber      = Get-HashedValue $BIOS.SerialNumber
                    BootDriveSerial           = $bootDriveSerial
                }

                # Generate OS telemetry using CIM (cross-edition compatible)
                $OS = Get-CimInstance -ClassName Win32_OperatingSystem

                $OSData = @{
                    OSType         = $OS.Caption
                    OSArchitecture = $OS.OSArchitecture
                    OSVersion      = $OS.Version
                    OSBuildNumber  = $OS.BuildNumber
                    SerialNumber   = Get-HashedValue $OS.SerialNumber
                }

                # Generate PowerShell telemetry
                $PSData = @{
                    PowerShellVersion = $PSVersionTable.PSVersion.ToString()
                    HostVersion       = $Host.Version.ToString()
                    HostName          = $Host.Name.ToString()
                    HostUI            = $Host.UI.ToString()
                    HostCulture       = $Host.CurrentCulture.ToString()
                    HostUICulture     = $Host.CurrentUICulture.ToString()
                }

                # Generate module telemetry
                $ModuleData = @{
                    ModuleName    = if ([string]::IsNullOrEmpty($Using:ModuleName)) { 'UnknownModule' } else { $Using:ModuleName }
                    ModuleVersion = if ([string]::IsNullOrEmpty($Using:ModuleVersion)) { 'UnknownModuleVersion' } else { $Using:ModuleVersion }
                    ModulePath    = if ([string]::IsNullOrEmpty($Using:ModulePath)) { 'UnknownModulePath' } else { $Using:ModulePath }
                    CommandName   = if ([string]::IsNullOrEmpty($Using:CommandName)) { 'UnknownCommand' } else { $Using:CommandName }
                }

                # Combine all telemetry data
                $AllData = @{}
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

                if ($Using:Minimal) {
                    $keysToKeep = @('ID', 'CommandName', 'ModuleName', 'ModuleVersion', 'LocalDateTime', 'ExecutionDuration', 'Stage', 'Failed', 'Exception', 'ExecutionID')
                    foreach ($key in @($AllData.Keys)) {
                        if ($key -notin $keysToKeep) {
                            $AllData[$key] = 'Minimal'
                        }
                    }
                }

                $body = $AllData | ConvertTo-Json
                Invoke-WebRequest @WebRequestArgs -Body $body | Out-Null
            } | Out-Null
            # Clear Old Jobs
            Get-Job -Name "TC_Job_Trying_To_Be_Unique_9000" -ErrorAction SilentlyContinue | Where-Object State -in Completed, Failed | Remove-Job -Force -ErrorAction SilentlyContinue | Out-Null
        }
    }
}
