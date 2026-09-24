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

Describe 'Write-Log' {
    It "Should format message with timestamp and level" {
        $tempFile = Join-Path -Path ([System.IO.Path]::GetTempPath()) -ChildPath "write-log-test-$(New-Guid).log"
        try {
            Write-Log -Message "Test message" -Level Info -LogPath $tempFile -NoConsole
            $content = Get-Content -Path $tempFile -Raw
            $content | Should -Match '^\[.+\]\[Info\] Test message'
        }
        finally {
            if (Test-Path $tempFile) { Remove-Item $tempFile -Force }
        }
    }

    It "Should write to file when LogPath specified" {
        $tempFile = Join-Path -Path ([System.IO.Path]::GetTempPath()) -ChildPath "write-log-test-$(New-Guid).log"
        try {
            Write-Log -Message "File test" -LogPath $tempFile -NoConsole
            Test-Path $tempFile | Should -BeTrue
            $content = Get-Content -Path $tempFile
            $content | Should -Not -BeNullOrEmpty
        }
        finally {
            if (Test-Path $tempFile) { Remove-Item $tempFile -Force }
        }
    }

    It "Should include component prefix when specified" {
        $tempFile = Join-Path -Path ([System.IO.Path]::GetTempPath()) -ChildPath "write-log-test-$(New-Guid).log"
        try {
            Write-Log -Message "Component test" -Component "MyModule" -LogPath $tempFile -NoConsole
            $content = Get-Content -Path $tempFile -Raw
            $content | Should -Match '\[MyModule\]'
        }
        finally {
            if (Test-Path $tempFile) { Remove-Item $tempFile -Force }
        }
    }

    It "Should handle pipeline input" {
        $tempFile = Join-Path -Path ([System.IO.Path]::GetTempPath()) -ChildPath "write-log-test-$(New-Guid).log"
        try {
            "Message1", "Message2", "Message3" | Write-Log -LogPath $tempFile -NoConsole
            $lines = Get-Content -Path $tempFile
            $lines.Count | Should -Be 3
            $lines[0] | Should -Match 'Message1'
            $lines[1] | Should -Match 'Message2'
            $lines[2] | Should -Match 'Message3'
        }
        finally {
            if (Test-Path $tempFile) { Remove-Item $tempFile -Force }
        }
    }
}

Describe 'Write-Log options' {
    It 'Returns the formatted line with -PassThru' {
        Write-Log -Message 'passthru' -NoConsole -PassThru | Should -Match '\[Info\] passthru$'
    }

    It 'Uses the given date format with -UseUtc' {
        $line = Write-Log -Message 'utc' -NoConsole -PassThru -UseUtc -DateFormat 'yyyy'
        $line | Should -BeExactly "[$([datetime]::UtcNow.Year)][Info] utc"
    }

    It 'Writes UTF-8 without a byte order mark' {
        $file = Join-Path $TestDrive 'nobom.log'
        Write-Log -Message 'bom' -LogPath $file -NoConsole
        $bytes = [System.IO.File]::ReadAllBytes($file)
        $bytes[0] | Should -Not -Be 0xEF
    }

    It 'Can append while another handle has the file open' {
        $file = Join-Path $TestDrive 'shared.log'
        $reader = [System.IO.File]::Open($file, 'OpenOrCreate', 'Read', 'ReadWrite')
        try {
            { Write-Log -Message 'shared' -LogPath $file -NoConsole } | Should -Not -Throw
        }
        finally {
            $reader.Dispose()
        }
    }

    It 'Writes Info to the information stream so it can be captured' {
        $captured = Write-Log -Message 'stream test' 6>&1
        "$captured" | Should -Match 'stream test'
    }

    It 'Writes Error messages to the error stream, not the host' {
        $errors = $null
        $hostOutput = Write-Log -Message 'boom' -Level Error -ErrorVariable errors -ErrorAction SilentlyContinue 6>&1
        $hostOutput | Should -BeNullOrEmpty
        $errors.Count | Should -Be 1
        $errors[0].ToString() | Should -Match '\[Error\] boom$'
    }

    It 'Writes Warning messages to the warning stream, not the host' {
        $warnings = $null
        $hostOutput = Write-Log -Message 'careful' -Level Warning -WarningVariable warnings -WarningAction SilentlyContinue 6>&1
        $hostOutput | Should -BeNullOrEmpty
        $warnings.Count | Should -Be 1
        [string]$warnings[0] | Should -Match '\[Warning\] careful$'
    }

    It 'Still logs Error messages to the file, even with -ErrorAction Stop' {
        $path = Join-Path -Path $TestDrive -ChildPath 'error-stop.log'
        { Write-Log -Message 'fatal' -Level Error -LogPath $path -ErrorAction Stop } | Should -Throw '*fatal*'
        Get-Content -Path $path | Should -Match '\[Error\] fatal$'
    }
}
