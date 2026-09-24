<#
.SYNOPSIS
    Imports a consumer module (tcs.azure, tcs.jira, ...) against this repository's tcs.core and
    runs the consumer's own smoke tests.

.DESCRIPTION
    Puts this repository's modules folder first on PSModulePath, so the consumer's
    RequiredModules entry for tcs.core loads the tcs.core being tested. Then imports the
    consumer module, checks which tcs.core was loaded, and runs the consumer's
    .github/scripts/module-smoke-tests.ps1 when it has one.

.PARAMETER ConsumerRoot
    The folder the consumer repository is checked out in.

.PARAMETER ModuleName
    The consumer module name, for example tcs.jira.

.EXAMPLE
    ./.github/scripts/consumer-smoke-tests.ps1 -ConsumerRoot ../TheCodeSaiyan-PowerShell-tcs.jira -ModuleName tcs.jira
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$ConsumerRoot,

    [Parameter(Mandatory)]
    [ValidatePattern('^[A-Za-z0-9][A-Za-z0-9._-]*$')]
    [string]$ModuleName
)

$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent
$modulesPath = Join-Path -Path $repoRoot -ChildPath 'modules'
$coreManifest = Join-Path -Path (Join-Path -Path $modulesPath -ChildPath 'tcs.core') -ChildPath 'tcs.core.psd1'
$consumerRootPath = (Resolve-Path -Path $ConsumerRoot).ProviderPath
$consumerManifest = Join-Path -Path (Join-Path -Path (Join-Path -Path $consumerRootPath -ChildPath 'modules') -ChildPath $ModuleName) -ChildPath "$ModuleName.psd1"
if (-not (Test-Path -Path $consumerManifest)) {
    throw "Consumer module manifest not found: $consumerManifest"
}

# This repository's tcs.core must win over any installed copy
$env:PSModulePath = $modulesPath + [System.IO.Path]::PathSeparator + $env:PSModulePath
$env:TCS_SKIP_UPDATE_CHECK = '1'
$env:TCS_TELEMETRY_OPTOUT = '1'
$env:TCS_CONFIG_ROOT = Join-Path -Path ([System.IO.Path]::GetTempPath()) -ChildPath "tcs-consumer-$([guid]::NewGuid().ToString('N'))"

try {
    Write-Output "Importing $ModuleName from $consumerManifest"
    Import-Module -Name $consumerManifest -Force -ErrorAction Stop

    $core = Get-Module -Name tcs.core
    $expectedVersion = (Import-PowerShellDataFile -Path $coreManifest).ModuleVersion
    if (-not $core -or $core.ModuleBase -ne (Split-Path -Path $coreManifest -Parent) -or [string]$core.Version -ne $expectedVersion) {
        throw "$ModuleName loaded tcs.core from '$($core.ModuleBase)' ($($core.Version)), not the tcs.core $expectedVersion under test."
    }
    Write-Output "$ModuleName imported with tcs.core $($core.Version) from $($core.ModuleBase)"
    Remove-Module -Name $ModuleName -Force -ErrorAction SilentlyContinue

    $smokeTests = Join-Path -Path (Join-Path -Path (Join-Path -Path $consumerRootPath -ChildPath '.github') -ChildPath 'scripts') -ChildPath 'module-smoke-tests.ps1'
    if (Test-Path -Path $smokeTests) {
        Write-Output "Running $smokeTests"
        & $smokeTests
    }
    else {
        Write-Output "$ModuleName has no smoke test script; the import check passed."
    }
    Write-Output "$ModuleName works with this tcs.core."
}
finally {
    Remove-Module -Name $ModuleName, tcs.core -Force -ErrorAction SilentlyContinue
    Remove-Item -Path $env:TCS_CONFIG_ROOT -Recurse -Force -ErrorAction SilentlyContinue
}
