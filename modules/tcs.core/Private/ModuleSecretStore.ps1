<#
.SYNOPSIS
    Internal helpers for Set-ModuleSecret, Get-ModuleSecret and Remove-ModuleSecret.

.DESCRIPTION
    Each secret is stored in its own file,
    <config root>/<ModuleName>/Secrets/<Name>.json, holding its type (SecureString or
    PSCredential), the user name for credentials, and the value protected with
    Protect-ConfigValue.

.NOTES
    Private helpers for the tcs.core module.
#>

function Get-ModuleSecretPath {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [string]$ModuleName,

        [Parameter(Mandatory)]
        [string]$Name
    )

    # Both names become path segments; reject anything that could leave the folder
    if (-not (Test-ModuleNameValid -Name $ModuleName)) {
        throw "'$ModuleName' is not a valid module name."
    }
    if (-not (Test-ModuleNameValid -Name $Name)) {
        throw "'$Name' is not a valid secret name. Use letters, digits, '.', '_' and '-', starting with a letter or digit."
    }
    $secretFolder = Join-Path -Path (Join-Path -Path (Get-ModuleConfigRoot) -ChildPath $ModuleName) -ChildPath 'Secrets'
    return (Join-Path -Path $secretFolder -ChildPath "$Name.json")
}
