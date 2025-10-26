<#
.SYNOPSIS
    Build and test script for the tcs.core PowerShell module.

.DESCRIPTION
    This script provides various functions for building, testing, and preparing the tcs.core module
    for publication. It can validate the module, run tests, update versions, and prepare releases.

.PARAMETER Task
    The task to perform. Valid options:
    - Validate: Run all validation checks
    - Test: Run validation and function tests
    - UpdateVersion: Update the module version
    - PrepareRelease: Prepare for a new release
    - Clean: Clean up build artifacts

.PARAMETER Version
    The new version to set (used with UpdateVersion task)

.PARAMETER WhatIf
    Show what would be done without actually doing it

.EXAMPLE
    .\Build.ps1 -Task Validate
    Runs validation checks on the module

.EXAMPLE
    .\Build.ps1 -Task UpdateVersion -Version "0.1.8"
    Updates the module version to 0.1.8

.EXAMPLE
    .\Build.ps1 -Task PrepareRelease -Version "0.1.8"
    Prepares a new release with version 0.1.8
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateSet('Validate', 'Test', 'UpdateVersion', 'PrepareRelease', 'Clean', 'Help')]
    [string]$Task,
    
    [string]$Version,
    
    [switch]$WhatIf
)

# Module configuration
$ModuleName = 'tcs.core'
$ModulePath = Join-Path $PSScriptRoot "module\$ModuleName"
$ManifestPath = Join-Path $ModulePath "$ModuleName.psd1"

function Write-TaskHeader {
    param([string]$Title)
    Write-Host "`n$('=' * 50)" -ForegroundColor Cyan
    Write-Host $Title.ToUpper() -ForegroundColor Cyan
    Write-Host $('=' * 50) -ForegroundColor Cyan
}

function Write-Success {
    param([string]$Message)
    Write-Host "✅ $Message" -ForegroundColor Green
}

function Write-Warning {
    param([string]$Message)
    Write-Host "⚠️ $Message" -ForegroundColor Yellow
}

function Write-Error {
    param([string]$Message)
    Write-Host "❌ $Message" -ForegroundColor Red
}

function Test-ModuleValidation {
    Write-TaskHeader "Module Validation"
    
    # Test manifest
    Write-Host "Testing module manifest..." -ForegroundColor Gray
    if (-not (Test-Path $ManifestPath)) {
        Write-Error "Module manifest not found at: $ManifestPath"
        return $false
    }
    
    try {
        $manifest = Test-ModuleManifest -Path $ManifestPath -ErrorAction Stop
        Write-Success "Module manifest is valid"
        Write-Host "  Module: $($manifest.Name)" -ForegroundColor Gray
        Write-Host "  Version: $($manifest.Version)" -ForegroundColor Gray
        Write-Host "  Author: $($manifest.Author)" -ForegroundColor Gray
    }
    catch {
        Write-Error "Module manifest validation failed: $_"
        return $false
    }
    
    # Test import
    Write-Host "Testing module import..." -ForegroundColor Gray
    try {
        Import-Module $ManifestPath -Force -ErrorAction Stop
        Write-Success "Module imports successfully"
        
        $exportedFunctions = (Get-Module $ModuleName).ExportedFunctions
        Write-Host "  Exported functions: $($exportedFunctions.Keys -join ', ')" -ForegroundColor Gray
        
        Remove-Module $ModuleName -Force
    }
    catch {
        Write-Error "Module import failed: $_"
        return $false
    }
    
    return $true
}

function Test-ScriptAnalyzer {
    Write-TaskHeader "PSScriptAnalyzer"
    
    if (-not (Get-Module -ListAvailable PSScriptAnalyzer)) {
        Write-Host "Installing PSScriptAnalyzer..." -ForegroundColor Gray
        Install-Module PSScriptAnalyzer -Force -Scope CurrentUser
    }
    
    $results = Invoke-ScriptAnalyzer -Path $ModulePath -Recurse -Severity Warning,Error
    
    if ($results) {
        $errors = ($results | Where-Object Severity -eq 'Error').Count
        $warnings = ($results | Where-Object Severity -eq 'Warning').Count
        
        Write-Host "Found $errors error(s) and $warnings warning(s):" -ForegroundColor Yellow
        $results | Format-Table ScriptName, Line, Column, RuleName, Message -Wrap
        
        if ($errors -gt 0) {
            Write-Error "PSScriptAnalyzer found errors"
            return $false
        } else {
            Write-Warning "PSScriptAnalyzer found warnings"
        }
    } else {
        Write-Success "No PSScriptAnalyzer issues found"
    }
    
    return $true
}

function Test-Functions {
    Write-TaskHeader "Function Testing"
    
    # Import module
    Import-Module $ManifestPath -Force
    
    try {
        # Test ConvertTo-CamelCase
        Write-Host "Testing ConvertTo-CamelCase..." -ForegroundColor Gray
        $testCases = @(
            @{ Input = "HelloWorld"; Expected = "helloWorld" }
            @{ Input = "XML"; Expected = "xML" }
            @{ Input = ""; Expected = "" }
            @{ Input = "A"; Expected = "a" }
        )
        
        foreach ($test in $testCases) {
            $result = ConvertTo-CamelCase -Value $test.Input
            if ($result -eq $test.Expected) {
                Write-Host "  ✅ '$($test.Input)' -> '$result'" -ForegroundColor Gray
            } else {
                Write-Error "ConvertTo-CamelCase failed: '$($test.Input)' -> '$result' (expected '$($test.Expected)')"
                return $false
            }
        }
        
        # Test New-DynamicParameter
        Write-Host "Testing New-DynamicParameter..." -ForegroundColor Gray
        $dynParam = New-DynamicParameter -Name "TestParam" -ParameterType ([string]) -Mandatory
        if ($dynParam.Name -eq "TestParam" -and $dynParam.Parameter) {
            Write-Host "  ✅ Dynamic parameter created successfully" -ForegroundColor Gray
        } else {
            Write-Error "New-DynamicParameter failed"
            return $false
        }
        
        Write-Success "All function tests passed"
        return $true
    }
    catch {
        Write-Error "Function testing failed: $_"
        return $false
    }
    finally {
        Remove-Module $ModuleName -Force -ErrorAction SilentlyContinue
    }
}

function Update-ModuleVersion {
    param([string]$NewVersion)
    
    Write-TaskHeader "Update Module Version"
    
    if (-not $NewVersion) {
        Write-Error "Version parameter is required"
        return $false
    }
    
    # Validate version format
    if (-not ($NewVersion -match '^\d+\.\d+\.\d+$')) {
        Write-Error "Version must be in format x.y.z (e.g., 0.1.8)"
        return $false
    }
    
    Write-Host "Updating version to $NewVersion..." -ForegroundColor Gray
    
    if ($WhatIf) {
        Write-Host "WHATIF: Would update version in $ManifestPath" -ForegroundColor Yellow
        return $true
    }
    
    # Read current manifest
    $manifestContent = Get-Content $ManifestPath -Raw
    
    # Update version
    $manifestContent = $manifestContent -replace "ModuleVersion\s*=\s*'[\d\.]+'", "ModuleVersion        = '$NewVersion'"
    
    # Update release notes
    $manifestContent = $manifestContent -replace "ReleaseNotes\s*=\s*'[^']*'", "ReleaseNotes = 'Version $NewVersion release'"
    
    # Write back to file
    Set-Content -Path $ManifestPath -Value $manifestContent -Encoding UTF8
    
    Write-Success "Version updated to $NewVersion"
    return $true
}

function Invoke-PrepareRelease {
    param([string]$NewVersion)
    
    Write-TaskHeader "Prepare Release"
    
    if (-not $NewVersion) {
        Write-Error "Version parameter is required"
        return $false
    }
    
    # Update version
    if (-not (Update-ModuleVersion -NewVersion $NewVersion)) {
        return $false
    }
    
    # Run validation
    if (-not (Test-ModuleValidation)) {
        Write-Error "Validation failed after version update"
        return $false
    }
    
    # Run tests
    if (-not (Test-Functions)) {
        Write-Error "Function tests failed after version update"
        return $false
    }
    
    Write-Success "Release preparation complete"
    Write-Host "`nNext steps:" -ForegroundColor Cyan
    Write-Host "1. Review the changes: git diff" -ForegroundColor Gray
    Write-Host "2. Commit the changes: git add . && git commit -m 'Release v$NewVersion'" -ForegroundColor Gray
    Write-Host "3. Create and push tag: git tag v$NewVersion && git push origin main && git push origin v$NewVersion" -ForegroundColor Gray
    Write-Host "4. GitHub Actions will automatically publish to PowerShell Gallery" -ForegroundColor Gray
    
    return $true
}

function Invoke-Clean {
    Write-TaskHeader "Clean Build Artifacts"
    
    $itemsToClean = @(
        "*.log",
        "TestResults.xml",
        "temp"
    )
    
    foreach ($item in $itemsToClean) {
        $path = Join-Path $PSScriptRoot $item
        if (Test-Path $path) {
            if ($WhatIf) {
                Write-Host "WHATIF: Would remove $path" -ForegroundColor Yellow
            } else {
                Remove-Item $path -Recurse -Force
                Write-Host "Removed: $path" -ForegroundColor Gray
            }
        }
    }
    
    Write-Success "Clean complete"
    return $true
}

function Show-Help {
    Write-TaskHeader "Build Script Help"
    
    Write-Host "Available tasks:" -ForegroundColor White
    Write-Host "  Validate       - Run module validation checks" -ForegroundColor Gray
    Write-Host "  Test          - Run validation and function tests" -ForegroundColor Gray
    Write-Host "  UpdateVersion - Update the module version" -ForegroundColor Gray
    Write-Host "  PrepareRelease- Prepare for a new release" -ForegroundColor Gray
    Write-Host "  Clean         - Clean up build artifacts" -ForegroundColor Gray
    Write-Host "  Help          - Show this help message" -ForegroundColor Gray
    
    Write-Host "`nExamples:" -ForegroundColor White
    Write-Host "  .\Build.ps1 -Task Validate" -ForegroundColor Gray
    Write-Host "  .\Build.ps1 -Task Test" -ForegroundColor Gray
    Write-Host "  .\Build.ps1 -Task UpdateVersion -Version '0.1.8'" -ForegroundColor Gray
    Write-Host "  .\Build.ps1 -Task PrepareRelease -Version '0.1.8'" -ForegroundColor Gray
}

# Main execution
switch ($Task) {
    'Validate' {
        $success = Test-ModuleValidation -and (Test-ScriptAnalyzer)
        exit $(if ($success) { 0 } else { 1 })
    }
    'Test' {
        $success = Test-ModuleValidation -and (Test-ScriptAnalyzer) -and (Test-Functions)
        exit $(if ($success) { 0 } else { 1 })
    }
    'UpdateVersion' {
        $success = Update-ModuleVersion -NewVersion $Version
        exit $(if ($success) { 0 } else { 1 })
    }
    'PrepareRelease' {
        $success = Invoke-PrepareRelease -NewVersion $Version
        exit $(if ($success) { 0 } else { 1 })
    }
    'Clean' {
        $success = Invoke-Clean
        exit $(if ($success) { 0 } else { 1 })
    }
    'Help' {
        Show-Help
        exit 0
    }
}