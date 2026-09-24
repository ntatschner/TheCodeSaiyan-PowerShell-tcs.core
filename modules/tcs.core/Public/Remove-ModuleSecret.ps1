<#
.SYNOPSIS
    Deletes a secret or credential saved with Set-ModuleSecret.

.DESCRIPTION
    The Remove-ModuleSecret function deletes the file that holds a secret saved for a module
    with Set-ModuleSecret. If no secret with that name is saved, a non-terminating error is
    written.

.PARAMETER ModuleName
    The module the secret belongs to, for example 'tcs.jira'.

.PARAMETER Name
    The name the secret was saved under.

.INPUTS
    None
    This function does not accept pipeline input.

.OUTPUTS
    None

.EXAMPLE
    Remove-ModuleSecret -ModuleName 'tcs.jira' -Name 'ApiToken'

    Deletes the saved token.

.EXAMPLE
    Remove-ModuleSecret -ModuleName 'tcs.jira' -Name 'ApiToken' -WhatIf

    Shows what would be deleted.

.NOTES
    Author: Nigel Tatschner
    Company: TheCodeSaiyan

.LINK
    Set-ModuleSecret

.LINK
    Get-ModuleSecret
#>
function Remove-ModuleSecret {
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([void])]
    param(
        [Parameter(Mandatory, Position = 0, HelpMessage = 'The module the secret belongs to.')]
        [ValidatePattern('^[A-Za-z0-9][A-Za-z0-9._-]*$')]
        [string]$ModuleName,

        [Parameter(Mandatory, Position = 1, HelpMessage = 'The name of the secret.')]
        [ValidatePattern('^[A-Za-z0-9][A-Za-z0-9._-]*$')]
        [string]$Name
    )

    $path = Get-ModuleSecretPath -ModuleName $ModuleName -Name $Name
    if (-not (Test-Path -LiteralPath $path)) {
        Write-Error -Message "No secret named '$Name' is saved for $ModuleName." -Category ObjectNotFound -TargetObject $Name -ErrorId 'ModuleSecretNotFound'
        return
    }
    if ($PSCmdlet.ShouldProcess("$ModuleName secret '$Name'", 'Remove secret')) {
        Remove-Item -LiteralPath $path -Force -ErrorAction Stop
    }
}
