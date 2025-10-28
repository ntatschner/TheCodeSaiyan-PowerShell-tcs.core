param()

$moduleName = 'tcs.core'
$repoRoot = Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent
$moduleDirectory = Join-Path -Path $repoRoot -ChildPath 'module/tcs.core'
$moduleManifest = Join-Path -Path $moduleDirectory -ChildPath 'tcs.core.psd1'

if (-not (Test-Path -Path $moduleManifest)) {
    throw "Module manifest not found at path: $moduleManifest"
}

try {
    Write-Host "Importing $moduleName from $moduleManifest" -ForegroundColor Cyan
    Import-Module -Name $moduleManifest -Force -ErrorAction Stop

    $camel = ConvertTo-CamelCase -Value 'HelloWorld'
    if ($camel -ne 'helloWorld') {
        throw "ConvertTo-CamelCase returned '$camel' (expected 'helloWorld')."
    }

    $dynamicParameter = New-DynamicParameter -Name 'TestParam' -ParameterType ([string]) -Mandatory
    if ($dynamicParameter.Name -ne 'TestParam' -or -not $dynamicParameter.Parameter) {
        throw 'New-DynamicParameter did not return the expected parameter definition.'
    }

    Write-Host 'All smoke tests passed successfully.' -ForegroundColor Green
}
finally {
    Remove-Module -Name $moduleName -Force -ErrorAction SilentlyContinue
}
