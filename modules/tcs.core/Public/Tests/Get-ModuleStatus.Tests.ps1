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

Describe 'Get-ModuleStatus' {
    BeforeAll {
        $fakeModule = Join-Path -Path $TestDrive -ChildPath 'tcs.fake'
        $null = New-Item -Path $fakeModule -ItemType Directory -Force
        "@{ ModuleVersion = '1.0.0' }" | Set-Content -Path (Join-Path $fakeModule 'tcs.fake.psd1')
        $cacheFile = Join-Path $env:TCS_CONFIG_ROOT 'tcs.fake/UpdateCheck.json'
        # Windows PowerShell 5.1 has no Find-PSResource, and Pester can only mock commands that exist
        if (-not (Get-Command -Name Find-PSResource -ErrorAction SilentlyContinue)) {
            function global:Find-PSResource { param($Name) }
            $script:StubbedFindPSResource = $true
        }
    }

    BeforeEach {
        Remove-Item -Path $cacheFile -Force -ErrorAction SilentlyContinue
        $env:TCS_SKIP_UPDATE_CHECK = $null
        Mock -ModuleName tcs.core Get-Command { $true } -ParameterFilter { $Name -eq 'Find-PSResource' }
        Mock -ModuleName tcs.core Find-PSResource { [PSCustomObject]@{ Version = [version]'2.0.0' } }
    }

    AfterAll {
        $env:TCS_SKIP_UPDATE_CHECK = '1'
        if ($script:StubbedFindPSResource) {
            Remove-Item -Path Function:\Find-PSResource -ErrorAction SilentlyContinue
        }
    }

    It 'Reports an available update and caches the result' {
        $status = Get-ModuleStatus -ModuleName 'tcs.fake' -ModulePath $fakeModule
        $status.UpdateAvailable | Should -BeTrue
        $status.LatestVersion | Should -Be ([version]'2.0.0')
        $status.Source | Should -Be 'Gallery'
        Test-Path $cacheFile | Should -BeTrue
    }

    It 'Uses the cache instead of the gallery within the cache window' {
        $null = Get-ModuleStatus -ModuleName 'tcs.fake' -ModulePath $fakeModule
        $status = Get-ModuleStatus -ModuleName 'tcs.fake' -ModulePath $fakeModule
        $status.Source | Should -Be 'Cache'
        $status.LatestVersion | Should -Be ([version]'2.0.0')
        Should -Invoke -ModuleName tcs.core Find-PSResource -Times 1 -Exactly
    }

    It 'Queries again once the cache has expired' {
        @{ LastChecked = [datetime]::UtcNow.AddHours(-25).ToString('o'); LatestVersion = '1.5.0' } | ConvertTo-Json | Set-Content -Path (New-Item -Path $cacheFile -Force)
        (Get-ModuleStatus -ModuleName 'tcs.fake' -ModulePath $fakeModule).Source | Should -Be 'Gallery'
    }

    It 'Caches failed lookups so offline imports do not retry every time' {
        Mock -ModuleName tcs.core Find-PSResource { throw 'offline' }
        $first = Get-ModuleStatus -ModuleName 'tcs.fake' -ModulePath $fakeModule
        $first.LatestVersion | Should -BeNullOrEmpty
        $first.UpdateAvailable | Should -BeFalse
        (Get-ModuleStatus -ModuleName 'tcs.fake' -ModulePath $fakeModule).Source | Should -Be 'Cache'
        Should -Invoke -ModuleName tcs.core Find-PSResource -Times 1 -Exactly
    }

    It 'Never writes an error, even when the lookup fails' {
        Mock -ModuleName tcs.core Find-PSResource { Write-Error 'not found' }
        $output = Get-ModuleStatus -ModuleName 'tcs.fake' -ModulePath $fakeModule 2>&1
        @($output | Where-Object { $_ -is [System.Management.Automation.ErrorRecord] }).Count | Should -Be 0
        @($output).Count | Should -Be 1
    }

    It 'Writes a warning with -ShowMessage when an update is available' {
        $null = Get-ModuleStatus -ModuleName 'tcs.fake' -ModulePath $fakeModule -ShowMessage -WarningVariable warnings -WarningAction SilentlyContinue
        $warnings.Count | Should -Be 1
    }

    It 'Skips the check when TCS_SKIP_UPDATE_CHECK is set' {
        $env:TCS_SKIP_UPDATE_CHECK = '1'
        (Get-ModuleStatus -ModuleName 'tcs.fake' -ModulePath $fakeModule).Source | Should -Be 'Skipped'
        Should -Invoke -ModuleName tcs.core Find-PSResource -Times 0 -Exactly
    }

    It 'Queries the gallery with -Force even when cached' {
        $null = Get-ModuleStatus -ModuleName 'tcs.fake' -ModulePath $fakeModule
        (Get-ModuleStatus -ModuleName 'tcs.fake' -ModulePath $fakeModule -Force).Source | Should -Be 'Gallery'
    }

    It 'Rejects a module name that is not a single safe folder name' {
        { Get-ModuleStatus -ModuleName '../escaped' -ModulePath $TestDrive } | Should -Throw
    }
}
