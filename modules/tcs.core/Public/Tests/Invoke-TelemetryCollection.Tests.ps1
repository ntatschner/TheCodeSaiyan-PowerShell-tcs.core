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

    It 'Honours Telemetry = $false in the settings file when the module has not loaded its settings' {
        InModuleScope tcs.core { $script:ModuleConfigCache.Remove('tcs.fileoff'); $script:TelemetryConfigCache.Clear() }
        $folder = Join-Path -Path $env:TCS_CONFIG_ROOT -ChildPath 'tcs.fileoff'
        $null = New-Item -Path $folder -ItemType Directory -Force
        '{ "Telemetry": false }' | Set-Content -Path (Join-Path $folder 'Module.Config.json')
        Invoke-TelemetryCollection -ModuleName 'tcs.fileoff' -ExecutionID 'e6b' -Stage Module-Load -URI $uri
        Should -Invoke -ModuleName tcs.core Send-TelemetryPayload -Times 0 -Exactly
    }

    It 'Honours a telemetry opt-out made with Set-ModuleConfig in the same session' {
        Invoke-TelemetryCollection -ModuleName 'tcs.lateoff' -ExecutionID 'e6c' -Stage Module-Load -URI $uri
        Set-ModuleConfig -ModuleName 'tcs.lateoff' -Telemetry $false
        Invoke-TelemetryCollection -ModuleName 'tcs.lateoff' -ExecutionID 'e6d' -Stage Module-Load -URI $uri
        Should -Invoke -ModuleName tcs.core Send-TelemetryPayload -Times 1 -Exactly
    }

    It 'Uses the endpoint from the settings file when the module has not loaded its settings' {
        InModuleScope tcs.core { $script:TelemetryConfigCache.Clear() }
        $folder = Join-Path -Path $env:TCS_CONFIG_ROOT -ChildPath 'tcs.fileuri'
        $null = New-Item -Path $folder -ItemType Directory -Force
        '{ "TelemetryUri": "https://file.example.com/ingest" }' | Set-Content -Path (Join-Path $folder 'Module.Config.json')
        Invoke-TelemetryCollection -ModuleName 'tcs.fileuri' -ExecutionID 'e6e' -Stage Module-Load
        Should -Invoke -ModuleName tcs.core Send-TelemetryPayload -Times 1 -Exactly -ParameterFilter { $Uri -eq 'https://file.example.com/ingest' }
    }

    It 'Decrypts a protected API key before sending' {
        Set-ModuleConfig -ModuleName 'tcs.keysend' -TelemetryApiKey 'SECRET-KEY' -TelemetryUri $uri
        Invoke-TelemetryCollection -ModuleName 'tcs.keysend' -ExecutionID 'e6f' -Stage Module-Load
        Should -Invoke -ModuleName tcs.core Send-TelemetryPayload -Times 1 -Exactly -ParameterFilter { $ApiKey -eq 'SECRET-KEY' }
    }

    It 'Still sends a plain-text API key saved by an earlier version' {
        InModuleScope tcs.core { $script:TelemetryConfigCache.Clear() }
        $folder = Join-Path -Path $env:TCS_CONFIG_ROOT -ChildPath 'tcs.plainkey'
        $null = New-Item -Path $folder -ItemType Directory -Force
        '{ "TelemetryApiKey": "PLAIN-KEY" }' | Set-Content -Path (Join-Path $folder 'Module.Config.json')
        Invoke-TelemetryCollection -ModuleName 'tcs.plainkey' -ExecutionID 'e6g' -Stage Module-Load -URI $uri
        Should -Invoke -ModuleName tcs.core Send-TelemetryPayload -Times 1 -Exactly -ParameterFilter { $ApiKey -eq 'PLAIN-KEY' }
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

Describe 'Invoke-TelemetryCollection deprecations' {
    BeforeEach {
        InModuleScope tcs.core { $script:DeprecationWarningsShown.Clear() }
    }

    It 'Warns once per session for <Name>, and keeps working' -ForEach @(
        @{ Name = '-ModulePath'; Arguments = @{ ModulePath = 'x'; Stage = 'Module-Load' }; Pattern = '-ModulePath is deprecated' }
        @{ Name = '-Minimal'; Arguments = @{ Minimal = $true; Stage = 'Module-Load' }; Pattern = '-Minimal is deprecated' }
        @{ Name = 'In-Progress'; Arguments = @{ Stage = 'In-Progress' }; Pattern = "'In-Progress' is deprecated" }
    ) {
        $warnings = $null
        Invoke-TelemetryCollection -ExecutionID 'd1' @Arguments -WarningVariable warnings -WarningAction SilentlyContinue
        Invoke-TelemetryCollection -ExecutionID 'd2' @Arguments -WarningVariable +warnings -WarningAction SilentlyContinue
        @($warnings).Count | Should -Be 1
        [string]$warnings[0] | Should -Match $Pattern
        [string]$warnings[0] | Should -Match '1\.0'
    }

    It 'Does not warn for current usage' {
        $warnings = $null
        Invoke-TelemetryCollection -ExecutionID 'd3' -Stage Start -WarningVariable warnings -WarningAction SilentlyContinue
        Invoke-TelemetryCollection -ExecutionID 'd3' -Stage End -WarningVariable +warnings -WarningAction SilentlyContinue
        @($warnings).Count | Should -Be 0
    }
}
