<#
.SYNOPSIS
    Build and test script for the tcs.core PowerShell module.

.DESCRIPTION
    Provides tasks for building, testing, and preparing the tcs.core module for publication.
    Uses PSScriptAnalyzer for linting and Pester for testing.

.PARAMETER Task
    The task to perform. Valid options:
    - Validate: Run module manifest validation
    - Lint: Run PSScriptAnalyzer
    - Test: Run Pester tests
    - All: Validate + Lint + Test
    - UpdateVersion: Update the module version
    - PrepareRelease: Prepare for a new release
    - Clean: Clean up build artifacts
    - Help: Show this help

.PARAMETER Version
    The new version to set (used with UpdateVersion and PrepareRelease tasks)

.PARAMETER WhatIf
    Show what would be done without actually doing it

.EXAMPLE
    .\Build.ps1 -Task All

.EXAMPLE
    .\Build.ps1 -Task PrepareRelease -Version "0.2.1"
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateSet('Validate', 'Lint', 'Test', 'All', 'UpdateVersion', 'PrepareRelease', 'Clean', 'Help')]
    [string]$Task,

    [string]$Version,

    [switch]$WhatIf
)

$ModuleName   = 'tcs.core'
$ModulePath   = Join-Path $PSScriptRoot "modules" $ModuleName
$ManifestPath = Join-Path $ModulePath "$ModuleName.psd1"
$TestsPath    = $ModulePath

function Write-TaskHeader {
    param([string]$Title)
    Write-Host "`n$('=' * 50)" -ForegroundColor Cyan
    Write-Host $Title.ToUpper() -ForegroundColor Cyan
    Write-Host $('=' * 50) -ForegroundColor Cyan
}

function Write-BuildSuccess {
    param([string]$Message)
    Write-Host "OK  $Message" -ForegroundColor Green
}

function Write-BuildWarning {
    param([string]$Message)
    Write-Host "WARN $Message" -ForegroundColor Yellow
}

function Write-BuildError {
    param([string]$Message)
    Write-Host "FAIL $Message" -ForegroundColor Red
}

function Test-ModuleValidation {
    Write-TaskHeader "Module Validation"

    if (-not (Test-Path $ManifestPath)) {
        Write-BuildError "Module manifest not found at: $ManifestPath"
        return $false
    }

    try {
        $manifest = Test-ModuleManifest -Path $ManifestPath -ErrorAction Stop
        Write-BuildSuccess "Module manifest is valid"
        Write-Host "  Module:  $($manifest.Name)" -ForegroundColor Gray
        Write-Host "  Version: $($manifest.Version)" -ForegroundColor Gray
        Write-Host "  Author:  $($manifest.Author)" -ForegroundColor Gray
    } catch {
        Write-BuildError "Module manifest validation failed: $_"
        return $false
    }

    try {
        Import-Module $ManifestPath -Force -ErrorAction Stop
        Write-BuildSuccess "Module imports successfully"
        $exportedFunctions = (Get-Module $ModuleName).ExportedFunctions
        Write-Host "  Exported functions: $($exportedFunctions.Keys -join ', ')" -ForegroundColor Gray
        Remove-Module $ModuleName -Force
    } catch {
        Write-BuildError "Module import failed: $_"
        return $false
    }

    return $true
}

function Test-Lint {
    Write-TaskHeader "PSScriptAnalyzer"

    if (-not (Get-Module -ListAvailable PSScriptAnalyzer)) {
        Write-Host "Installing PSScriptAnalyzer..." -ForegroundColor Gray
        Install-Module PSScriptAnalyzer -Force -Scope CurrentUser
    }

    $results = Invoke-ScriptAnalyzer -Path $ModulePath -Recurse -Severity Warning, Error

    if ($results) {
        $errors   = ($results | Where-Object Severity -eq 'Error').Count
        $warnings = ($results | Where-Object Severity -eq 'Warning').Count

        Write-Host "Found $errors error(s) and $warnings warning(s):" -ForegroundColor Yellow
        $results | Format-Table ScriptName, Line, Column, RuleName, Message -Wrap

        if ($errors -gt 0) {
            Write-BuildError "PSScriptAnalyzer found $errors error(s)"
            return $false
        } else {
            Write-BuildWarning "PSScriptAnalyzer found $warnings warning(s)"
        }
    } else {
        Write-BuildSuccess "No PSScriptAnalyzer issues found"
    }

    return $true
}

function Invoke-Tests {
    Write-TaskHeader "Pester Tests"

    if (-not (Get-Module -ListAvailable Pester | Where-Object Version -ge '5.0')) {
        Write-Host "Installing Pester 5+..." -ForegroundColor Gray
        Install-Module Pester -MinimumVersion 5.0 -Force -Scope CurrentUser
    }

    $pesterConfig = New-PesterConfiguration
    $pesterConfig.Run.Path = $TestsPath
    $pesterConfig.Run.Recurse = $true
    $pesterConfig.TestResult.Enabled = $true
    $pesterConfig.TestResult.OutputPath = Join-Path $PSScriptRoot "TestResults.xml"
    $pesterConfig.Output.Verbosity = 'Detailed'

    $result = Invoke-Pester -Configuration $pesterConfig

    if ($result.FailedCount -gt 0) {
        Write-BuildError "$($result.FailedCount) Pester test(s) failed"
        return $false
    }

    Write-BuildSuccess "$($result.PassedCount) Pester test(s) passed"
    return $true
}

function Update-ModuleVersion {
    param([string]$NewVersion)

    Write-TaskHeader "Update Module Version"

    if (-not $NewVersion) {
        Write-BuildError "Version parameter is required"
        return $false
    }

    if (-not ($NewVersion -match '^\d+\.\d+\.\d+$')) {
        Write-BuildError "Version must be in format x.y.z"
        return $false
    }

    if ($WhatIf) {
        Write-Host "WHATIF: Would update version to $NewVersion in $ManifestPath" -ForegroundColor Yellow
        return $true
    }

    $manifestContent = Get-Content $ManifestPath -Raw
    $manifestContent = $manifestContent -replace "ModuleVersion\s*=\s*'[\d\.]+'", "ModuleVersion        = '$NewVersion'"
    $manifestContent = $manifestContent -replace "ReleaseNotes\s*=\s*'[^']*'", "ReleaseNotes = 'Version $NewVersion release'"
    Set-Content -Path $ManifestPath -Value $manifestContent -Encoding UTF8

    Write-BuildSuccess "Version updated to $NewVersion"
    return $true
}

function Invoke-PrepareRelease {
    param([string]$NewVersion)

    Write-TaskHeader "Prepare Release"

    if (-not $NewVersion) {
        Write-BuildError "Version parameter is required"
        return $false
    }

    if (-not (Update-ModuleVersion -NewVersion $NewVersion)) { return $false }
    if (-not (Test-ModuleValidation)) { return $false }
    if (-not (Test-Lint)) { return $false }
    if (-not (Invoke-Tests)) { return $false }

    Write-BuildSuccess "Release preparation complete for v$NewVersion"
    Write-Host "`nNext steps:" -ForegroundColor Cyan
    Write-Host "  git diff" -ForegroundColor Gray
    Write-Host "  git add . && git commit -m 'Release v$NewVersion'" -ForegroundColor Gray
    Write-Host "  git tag v$NewVersion && git push origin main && git push origin v$NewVersion" -ForegroundColor Gray

    return $true
}

function Invoke-Clean {
    Write-TaskHeader "Clean Build Artifacts"

    @('*.log', 'TestResults.xml', 'temp') | ForEach-Object {
        $path = Join-Path $PSScriptRoot $_
        if (Test-Path $path) {
            if ($WhatIf) {
                Write-Host "WHATIF: Would remove $path" -ForegroundColor Yellow
            } else {
                Remove-Item $path -Recurse -Force
                Write-Host "Removed: $path" -ForegroundColor Gray
            }
        }
    }

    Write-BuildSuccess "Clean complete"
    return $true
}

function Show-Help {
    Write-TaskHeader "Build Script Help"
    Write-Host "Tasks:" -ForegroundColor White
    Write-Host "  Validate       - Validate module manifest and import" -ForegroundColor Gray
    Write-Host "  Lint           - Run PSScriptAnalyzer" -ForegroundColor Gray
    Write-Host "  Test           - Run Pester tests" -ForegroundColor Gray
    Write-Host "  All            - Validate + Lint + Test" -ForegroundColor Gray
    Write-Host "  UpdateVersion  - Update module version (requires -Version)" -ForegroundColor Gray
    Write-Host "  PrepareRelease - Full release prep (requires -Version)" -ForegroundColor Gray
    Write-Host "  Clean          - Remove build artifacts" -ForegroundColor Gray
    Write-Host "  Help           - Show this help" -ForegroundColor Gray
}

switch ($Task) {
    'Validate'      { exit $(if (Test-ModuleValidation) { 0 } else { 1 }) }
    'Lint'          { exit $(if (Test-Lint) { 0 } else { 1 }) }
    'Test'          { exit $(if (Invoke-Tests) { 0 } else { 1 }) }
    'All'           { exit $(if ((Test-ModuleValidation) -and (Test-Lint) -and (Invoke-Tests)) { 0 } else { 1 }) }
    'UpdateVersion' { exit $(if (Update-ModuleVersion -NewVersion $Version) { 0 } else { 1 }) }
    'PrepareRelease'{ exit $(if (Invoke-PrepareRelease -NewVersion $Version) { 0 } else { 1 }) }
    'Clean'         { exit $(if (Invoke-Clean) { 0 } else { 1 }) }
    'Help'          { Show-Help; exit 0 }
}
