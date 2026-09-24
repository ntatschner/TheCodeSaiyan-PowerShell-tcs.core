BeforeAll {
    $env:TCS_CONFIG_ROOT = Join-Path -Path $TestDrive -ChildPath 'config'
    $env:TCS_SKIP_UPDATE_CHECK = '1'
    $env:TCS_TELEMETRY_OPTOUT = '1'
    $ModuleRoot = Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent
    Import-Module -Name (Join-Path -Path $ModuleRoot -ChildPath 'tcs.core.psd1') -Force

    # A consumer module whose exported commands use the wrapper
    $null = New-Module -Name tcs.wrapfake -ScriptBlock {
        function Get-Inner { [CmdletBinding()] param($X) Invoke-TcsCommand -ScriptBlock { "inner $X" } }
        function Get-Outer { [CmdletBinding()] param($X) Invoke-TcsCommand -ScriptBlock { 'outer'; Get-Inner -X $X } }
        function Get-NonTerminating { [CmdletBinding()] param() Invoke-TcsCommand -ScriptBlock { Write-Error 'not terminating'; 'after' } }
        function Get-Throws { [CmdletBinding()] param() Invoke-TcsCommand -ScriptBlock { throw [System.IO.IOException]::new('boom') } }
        function Get-Array { [CmdletBinding()] param() Invoke-TcsCommand -ScriptBlock { , @(1) } }
        function Get-Nothing { [CmdletBinding()] param() Invoke-TcsCommand -ScriptBlock { $null = 1 } }
        function Get-Handled {
            [CmdletBinding()]
            param()
            Invoke-TcsCommand -ScriptBlock {
                try { Get-Item -Path (Join-Path $TestDrive 'missing') -ErrorAction Stop } catch { 'handled' }
                $null = Get-Item -Path (Join-Path $TestDrive 'missing') -ErrorAction SilentlyContinue
                [System.Management.Automation.ErrorRecord]::new([System.Exception]::new('as data'), 'Data', 'NotSpecified', $null)
            }
        }
        function Set-Local { [CmdletBinding()] param() $value = 1; Invoke-TcsCommand -ScriptBlock { $value = 2 }; $value }
        function Test-ShouldProcess { [CmdletBinding(SupportsShouldProcess)] param() Invoke-TcsCommand -ScriptBlock { $PSCmdlet.ShouldProcess('target', 'action') } }
        function Get-Pipeline {
            [CmdletBinding()]
            param([Parameter(ValueFromPipeline)]$InputObject)
            begin { $telemetry = Start-TcsTelemetry; $count = 0 }
            process {
                Invoke-TcsCommand -Token $telemetry -ScriptBlock {
                    $count++
                    if ($InputObject -eq 'bad') { Write-Error "bad item" }
                    if ($InputObject -eq 'stop') { throw 'stopped' }
                    $null = Get-Inner -X $InputObject
                    $InputObject
                }
            }
            end { "count=$count"; Complete-TcsTelemetry -Token $telemetry }
        }
        Export-ModuleMember -Function *
    } | Import-Module -PassThru -Force
}

AfterAll {
    Remove-Module -Name tcs.wrapfake -Force -ErrorAction SilentlyContinue
    Remove-Module -Name tcs.core -Force -ErrorAction SilentlyContinue
}

Describe 'Invoke-TcsCommand' {
    BeforeEach {
        $env:TCS_TELEMETRY_OPTOUT = $null
        $env:TCS_TELEMETRY_URI = 'https://telemetry.example.com/ingest'
        Mock -ModuleName tcs.core Send-TelemetryPayload { }
    }

    AfterAll {
        $env:TCS_TELEMETRY_OPTOUT = '1'
        $env:TCS_TELEMETRY_URI = $null
    }

    It 'Reports a successful run with the calling command, module and version' {
        Get-Inner -X 1 | Should -Be 'inner 1'
        Should -Invoke -ModuleName tcs.core Send-TelemetryPayload -Times 1 -Exactly -ParameterFilter {
            $body = $Body | ConvertFrom-Json
            $body.command_name -eq 'Get-Inner' -and $body.module_name -eq 'tcs.wrapfake' -and $body.version -eq '0.0' -and $body.success -eq $true
        }
    }

    It 'Uses the names that are passed' {
        $null = Invoke-TcsCommand -ScriptBlock { 1 } -CommandName 'Get-Named' -ModuleName 'tcs.named' -ModuleVersion '9.9.9'
        Should -Invoke -ModuleName tcs.core Send-TelemetryPayload -Times 1 -Exactly -ParameterFilter {
            $body = $Body | ConvertFrom-Json
            $body.command_name -eq 'Get-Named' -and $body.module_name -eq 'tcs.named' -and $body.version -eq '9.9.9'
        }
    }

    It 'Reports only the outermost command when a command calls another command of the same module' {
        Get-Outer -X 1 | Should -Be @('outer', 'inner 1')
        Should -Invoke -ModuleName tcs.core Send-TelemetryPayload -Times 1 -Exactly
        Should -Invoke -ModuleName tcs.core Send-TelemetryPayload -Times 1 -Exactly -ParameterFilter { ($Body | ConvertFrom-Json).command_name -eq 'Get-Outer' }
    }

    It 'Marks the run failed when the command writes a non-terminating error, and passes the error on' {
        $output = Get-NonTerminating -ErrorVariable errs 2>$null
        $output | Should -Be 'after'
        $errs.Count | Should -Be 1
        Should -Invoke -ModuleName tcs.core Send-TelemetryPayload -Times 1 -Exactly -ParameterFilter {
            $body = $Body | ConvertFrom-Json
            $body.success -eq $false -and $body.error_type -eq 'Microsoft.PowerShell.Commands.WriteErrorException'
        }
    }

    It 'Does not count handled or silenced errors, or error records written as output' {
        $output = Get-Handled 2>&1
        $output.Count | Should -Be 2
        $output[0] | Should -Be 'handled'
        $output[1] | Should -BeOfType [System.Management.Automation.ErrorRecord]
        Should -Invoke -ModuleName tcs.core Send-TelemetryPayload -Times 1 -Exactly -ParameterFilter { ($Body | ConvertFrom-Json).success -eq $true }
    }

    It 'Rethrows terminating errors unchanged and marks the run failed' {
        $caught = $null
        try { Get-Throws } catch { $caught = $_ }
        $caught.Exception | Should -BeOfType [System.IO.IOException]
        $caught.Exception.Message | Should -Be 'boom'
        Should -Invoke -ModuleName tcs.core Send-TelemetryPayload -Times 1 -Exactly -ParameterFilter {
            $body = $Body | ConvertFrom-Json
            $body.success -eq $false -and $body.error_type -eq 'System.IO.IOException' -and $Body -notmatch 'boom'
        }
    }

    It 'Honours -ErrorAction Stop on the calling command' {
        { Get-NonTerminating -ErrorAction Stop } | Should -Throw 'not terminating'
        Should -Invoke -ModuleName tcs.core Send-TelemetryPayload -Times 1 -Exactly -ParameterFilter { ($Body | ConvertFrom-Json).success -eq $false }
    }

    It 'Writes only the script block output, without unrolling or adding anything' {
        $result = Get-Array
        , $result | Should -BeOfType [object[]]
        $result.Count | Should -Be 1
        @(Get-Nothing).Count | Should -Be 0
    }

    It 'Runs the script block in the scope of the calling command' {
        Set-Local | Should -Be 2
        Test-ShouldProcess -WhatIf | Should -BeFalse
    }

    It 'Never breaks the command when telemetry fails' {
        Mock -ModuleName tcs.core Invoke-TelemetryCollection { throw 'telemetry broken' }
        Get-Inner -X 2 2>&1 | Should -Be 'inner 2'
        Mock -ModuleName tcs.core New-TcsTelemetryToken { throw 'token broken' }
        Get-Inner -X 3 2>&1 | Should -Be 'inner 3'
    }

    It 'Sends nothing when telemetry is turned off' {
        $env:TCS_TELEMETRY_OPTOUT = '1'
        Get-Inner -X 1 | Should -Be 'inner 1'
        Should -Invoke -ModuleName tcs.core Send-TelemetryPayload -Times 0 -Exactly
    }
}

Describe 'Start-TcsTelemetry and Complete-TcsTelemetry' {
    BeforeEach {
        $env:TCS_TELEMETRY_OPTOUT = $null
        $env:TCS_TELEMETRY_URI = 'https://telemetry.example.com/ingest'
        Mock -ModuleName tcs.core Send-TelemetryPayload { }
    }

    AfterAll {
        $env:TCS_TELEMETRY_OPTOUT = '1'
        $env:TCS_TELEMETRY_URI = $null
    }

    It 'Sends one event for a whole pipeline run and skips nested commands' {
        'a', 'b' | Get-Pipeline | Should -Be @('a', 'b', 'count=2')
        Should -Invoke -ModuleName tcs.core Send-TelemetryPayload -Times 1 -Exactly
        Should -Invoke -ModuleName tcs.core Send-TelemetryPayload -Times 1 -Exactly -ParameterFilter {
            $body = $Body | ConvertFrom-Json
            $body.command_name -eq 'Get-Pipeline' -and $body.success -eq $true
        }
    }

    It 'Marks a pipeline run failed when one item wrote an error' {
        $null = 'a', 'bad', 'c' | Get-Pipeline 2>$null
        Should -Invoke -ModuleName tcs.core Send-TelemetryPayload -Times 1 -Exactly -ParameterFilter { ($Body | ConvertFrom-Json).success -eq $false }
    }

    It 'Completes the run as failed when a process block throws' {
        { 'a', 'stop', 'c' | Get-Pipeline } | Should -Throw 'stopped'
        Should -Invoke -ModuleName tcs.core Send-TelemetryPayload -Times 1 -Exactly -ParameterFilter { ($Body | ConvertFrom-Json).success -eq $false }
    }

    It 'Completes the run when a downstream command stops the pipeline early' {
        'a', 'b', 'c' | Get-Pipeline | Select-Object -First 1 | Should -Be 'a'
        Should -Invoke -ModuleName tcs.core Send-TelemetryPayload -Times 1 -Exactly -ParameterFilter {
            $body = $Body | ConvertFrom-Json
            $body.command_name -eq 'Get-Pipeline' -and $body.success -eq $true
        }
        # A run that never reached its end block does not hide later runs
        Get-Inner -X 1 | Should -Be 'inner 1'
        Should -Invoke -ModuleName tcs.core Send-TelemetryPayload -Times 1 -Exactly -ParameterFilter { ($Body | ConvertFrom-Json).command_name -eq 'Get-Inner' }
    }

    It 'Returns a token with the given names and sends only once when completed twice' {
        $token = Start-TcsTelemetry -CommandName 'Get-Token' -ModuleName 'tcs.token' -ModuleVersion '1.0.0'
        $token.PSObject.TypeNames | Should -Contain 'Tcs.TelemetryToken'
        $token.IsOutermost | Should -BeTrue
        Complete-TcsTelemetry -Token $token -Failed
        $token | Complete-TcsTelemetry
        $token.Completed | Should -BeTrue
        Should -Invoke -ModuleName tcs.core Send-TelemetryPayload -Times 1 -Exactly -ParameterFilter {
            $body = $Body | ConvertFrom-Json
            $body.command_name -eq 'Get-Token' -and $body.success -eq $false
        }
    }

    It 'Reports the type of an error passed to Complete-TcsTelemetry' {
        $token = Start-TcsTelemetry -ModuleName 'tcs.token'
        try { throw [System.TimeoutException]::new('slow') } catch { Complete-TcsTelemetry -Token $token -ErrorRecord $_ }
        Should -Invoke -ModuleName tcs.core Send-TelemetryPayload -Times 1 -Exactly -ParameterFilter { ($Body | ConvertFrom-Json).error_type -eq 'System.TimeoutException' }
    }

    It 'Writes nothing to the pipeline when completing' {
        $token = Start-TcsTelemetry -ModuleName 'tcs.token'
        @(Complete-TcsTelemetry -Token $token).Count | Should -Be 0
    }

    It 'Still returns a usable token when telemetry fails' {
        Mock -ModuleName tcs.core New-TcsTelemetryToken { throw 'broken' }
        $token = Start-TcsTelemetry -CommandName 'Get-X'
        $token.IsOutermost | Should -BeFalse
        { Complete-TcsTelemetry -Token $token } | Should -Not -Throw
    }
}
