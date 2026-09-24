<#
.SYNOPSIS
    Reads a secret or credential saved with Set-ModuleSecret.

.DESCRIPTION
    The Get-ModuleSecret function decrypts a secret saved for a module with Set-ModuleSecret
    and returns it as the type that was saved: a SecureString, or a PSCredential. The value
    is never returned in plain text.

    If no secret with that name is saved, or it cannot be decrypted (for example it was
    saved by another user or on another machine), a non-terminating error is written. Use
    -ErrorAction SilentlyContinue to get nothing instead.

.PARAMETER ModuleName
    The module the secret belongs to, for example 'tcs.jira'.

.PARAMETER Name
    The name the secret was saved under.

.INPUTS
    None
    This function does not accept pipeline input.

.OUTPUTS
    System.Security.SecureString
    System.Management.Automation.PSCredential

.EXAMPLE
    $token = Get-ModuleSecret -ModuleName 'tcs.jira' -Name 'ApiToken'

    Returns the saved token as a SecureString.

.EXAMPLE
    $credential = Get-ModuleSecret -ModuleName 'tcs.confluence' -Name 'Default' -ErrorAction SilentlyContinue
    if (-not $credential) { $credential = Get-Credential }

    Uses the saved credential, or asks for one when none is saved.

.NOTES
    Author: Nigel Tatschner
    Company: TheCodeSaiyan

.LINK
    Set-ModuleSecret

.LINK
    Remove-ModuleSecret
#>
function Get-ModuleSecret {
    [CmdletBinding()]
    [OutputType([System.Security.SecureString], [System.Management.Automation.PSCredential])]
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
        Write-Error -Message "No secret named '$Name' is saved for $ModuleName. Save one with Set-ModuleSecret." -Category ObjectNotFound -TargetObject $Name -ErrorId 'ModuleSecretNotFound'
        return
    }

    try {
        $data = Read-JsonFileAsHashtable -Path $path
        $value = [string]$data['Value']
        if ([string]::IsNullOrEmpty($value)) {
            $secureString = New-Object System.Security.SecureString
        }
        else {
            $secureString = Unprotect-ConfigValue -EncryptedValue $value -AsSecureString -ErrorAction Stop
        }
        if ($data['Type'] -eq 'PSCredential') {
            return (New-Object System.Management.Automation.PSCredential -ArgumentList ([string]$data['UserName']), $secureString)
        }
        return $secureString
    }
    catch {
        Write-Error -Message "The secret '$Name' for $ModuleName could not be read. $($_.Exception.Message)" -Category ReadError -TargetObject $Name -ErrorId 'ModuleSecretUnreadable'
    }
}
