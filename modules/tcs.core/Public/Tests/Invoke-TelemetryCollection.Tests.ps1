BeforeAll {
    $env:TCS_CONFIG_ROOT = Join-Path -Path $TestDrive -ChildPath 'config'
    $env:TCS_SKIP_UPDATE_CHECK = '1'
    $env:TCS_TELEMETRY_OPTOUT = '1'
    $ModuleRoot = Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent
    Import-Module -Name (Join-Path -Path $ModuleRoot -ChildPath 'tcs.core.psd1') -Force
}

AfterAll {
    Remove-Module -Name tcs.core -Force -ErrorAction SilentlyContinue
}

Describe 'Invoke-TelemetryCollection' {
    BeforeAll {
        $uri = 'https://telemetry.example.com/ingest/powershell'
    }

    BeforeEach {
        $env:TCS_TELEMETRY_OPTOUT = $null
        $env:TCS_TELEMETRY_URI = $null
        Mock -ModuleName tcs.core Send-TelemetryPayload { }
    }

    AfterAll {
        $env:TCS_TELEMETRY_OPTOUT = '1'
    }

    It 'Sends one event on End with the measured duration and the ingestion schema' {
        Invoke-TelemetryCollection -ModuleName 'tcs.x' -ModuleVersion '1.0.0' -CommandName 'Get-X' -ExecutionID 'e1' -Stage Start -URI $uri
        Start-Sleep -Milliseconds 50
        Invoke-TelemetryCollection -ModuleName 'tcs.x' -ModuleVersion '1.0.0' -CommandName 'Get-X' -ExecutionID 'e1' -Stage End -URI $uri -ApiKey 'key'

        Should -Invoke -ModuleName tcs.core Send-TelemetryPayload -Times 1 -Exactly -ParameterFilter {
            $body = $Body | ConvertFrom-Json
            $Uri -eq 'https://telemetry.example.com/ingest/powershell' -and $ApiKey -eq 'key' -and
            $body.command_name -eq 'Get-X' -and $body.module_name -eq 'tcs.x' -and $body.version -eq '1.0.0' -and
            $body.duration_ms -ge 40 -and $body.success -eq $true -and $body.tags.stage -eq 'End' -and
            $body.os_platform -and $body.ps_version -and $body.host_name -match '^[0-9a-f-]{36}$'
        }
    }

    It 'Sends only the exception type, never the message, user or path' {
        $err = [System.IO.IOException]::new('C:\Users\secret\file.txt')
        Invoke-TelemetryCollection -ModuleName 'tcs.x' -ExecutionID 'e2' -Stage End -Failed $true -Exception $err -URI $uri -ModulePath 'C:\Users\secret'
        Should -Invoke -ModuleName tcs.core Send-TelemetryPayload -Times 1 -Exactly -ParameterFilter {
            $Body -notmatch 'secret' -and ($Body | ConvertFrom-Json).error_type -eq 'System.IO.IOException' -and
            ($Body | ConvertFrom-Json).success -eq $false -and $Body -notmatch [regex]::Escape([Environment]::UserName) -and $Body -notmatch [regex]::Escape([Environment]::MachineName)
        }
    }

    It 'Accepts an ErrorRecord as the exception' {
        try { throw [System.InvalidOperationException]::new('boom') } catch { $record = $_ }
        Invoke-TelemetryCollection -ModuleName 'tcs.x' -ExecutionID 'e3' -Stage End -Failed $true -Exception $record -URI $uri
        Should -Invoke -ModuleName tcs.core Send-TelemetryPayload -Times 1 -Exactly -ParameterFilter { ($Body | ConvertFrom-Json).error_type -eq 'System.InvalidOperationException' }
    }

    It 'Does not send on Start or In-Progress' {
        Invoke-TelemetryCollection -ModuleName 'tcs.x' -ExecutionID 'e4' -Stage Start -URI $uri
        Invoke-TelemetryCollection -ModuleName 'tcs.x' -ExecutionID 'e4' -Stage 'In-Progress' -URI $uri
        Should -Invoke -ModuleName tcs.core Send-TelemetryPayload -Times 0 -Exactly
    }

    It 'Sends nothing when TCS_TELEMETRY_OPTOUT is set' {
        $env:TCS_TELEMETRY_OPTOUT = '1'
        Invoke-TelemetryCollection -ModuleName 'tcs.x' -ExecutionID 'e5' -Stage Module-Load -URI $uri
        Should -Invoke -ModuleName tcs.core Send-TelemetryPayload -Times 0 -Exactly
    }

    It 'Sends nothing when the module has telemetry turned off' {
        InModuleScope tcs.core { $script:ModuleConfigCache['tcs.off'] = @{ Telemetry = $false } }
        Invoke-TelemetryCollection -ModuleName 'tcs.off' -ExecutionID 'e6' -Stage Module-Load -URI $uri
        Should -Invoke -ModuleName tcs.core Send-TelemetryPayload -Times 0 -Exactly
    }

    It 'Sends nothing when no endpoint is configured' {
        Invoke-TelemetryCollection -ModuleName 'tcs.x' -ExecutionID 'e7' -Stage Module-Load
        Should -Invoke -ModuleName tcs.core Send-TelemetryPayload -Times 0 -Exactly
    }

    It 'Uses TCS_TELEMETRY_URI when no URI is passed' {
        $env:TCS_TELEMETRY_URI = $uri
        Invoke-TelemetryCollection -ModuleName 'tcs.x' -ExecutionID 'e8' -Stage Module-Load
        Should -Invoke -ModuleName tcs.core Send-TelemetryPayload -Times 1 -Exactly -ParameterFilter { $Uri -eq 'https://telemetry.example.com/ingest/powershell' }
    }

    It 'Refuses non-HTTPS endpoints other than localhost' {
        Invoke-TelemetryCollection -ModuleName 'tcs.x' -ExecutionID 'e9' -Stage Module-Load -URI 'http://telemetry.example.com/ingest'
        Should -Invoke -ModuleName tcs.core Send-TelemetryPayload -Times 0 -Exactly
    }

    It 'Never throws, even if sending fails' {
        Mock -ModuleName tcs.core Send-TelemetryPayload { throw 'network down' }
        { Invoke-TelemetryCollection -ModuleName 'tcs.x' -ExecutionID 'e10' -Stage Module-Load -URI $uri } | Should -Not -Throw
    }

    It 'Keeps the same installation ID across calls' {
        $first = InModuleScope tcs.core { Get-TelemetryInstallationId }
        InModuleScope tcs.core { $script:TelemetryInstallationId = $null }
        InModuleScope tcs.core { Get-TelemetryInstallationId } | Should -Be $first
    }
}
