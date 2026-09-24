<#
.SYNOPSIS
    Saves a secret or credential for a tcs module, encrypted for the current user.

.DESCRIPTION
    The Set-ModuleSecret function saves a SecureString (such as an API token) or a
    PSCredential under a name, for one module. The value is encrypted with
    Protect-ConfigValue (DPAPI on Windows, AES-256 + HMAC on Linux/macOS) and stored in the
    module's settings folder:

      <ApplicationData>/PowerShell/Config/<ModuleName>/Secrets/<Name>.json

    An existing secret with the same name is replaced. Read it back with Get-ModuleSecret,
    which returns the same type that was saved.

.PARAMETER ModuleName
    The module the secret belongs to, for example 'tcs.jira'.

.PARAMETER Name
    The name of the secret, for example 'ApiToken'. Letters, digits, '.', '_' and '-' only,
    starting with a letter or digit.

.PARAMETER SecureString
    The secret to save.

.PARAMETER Credential
    The credential to save. The user name is stored as it is; the password is encrypted.

.PARAMETER Scope
    Who can decrypt the secret: 'CurrentUser' (default) or 'LocalMachine'. See
    Protect-ConfigValue.

.INPUTS
    None
    This function does not accept pipeline input.

.OUTPUTS
    None

.EXAMPLE
    Set-ModuleSecret -ModuleName 'tcs.jira' -Name 'ApiToken' -SecureString (Read-Host -AsSecureString -Prompt 'Token')

    Saves an API token for tcs.jira.

.EXAMPLE
    Set-ModuleSecret -ModuleName 'tcs.confluence' -Name 'Default' -Credential (Get-Credential)

    Saves a user name and password for tcs.confluence.

.NOTES
    Author: Nigel Tatschner
    Company: TheCodeSaiyan

.LINK
    Get-ModuleSecret

.LINK
    Remove-ModuleSecret
#>
function Set-ModuleSecret {
    [CmdletBinding(SupportsShouldProcess, DefaultParameterSetName = 'SecureString')]
    [OutputType([void])]
    param(
        [Parameter(Mandatory, Position = 0, HelpMessage = 'The module the secret belongs to.')]
        [ValidatePattern('^[A-Za-z0-9][A-Za-z0-9._-]*$')]
        [string]$ModuleName,

        [Parameter(Mandatory, Position = 1, HelpMessage = 'The name of the secret.')]
        [ValidatePattern('^[A-Za-z0-9][A-Za-z0-9._-]*$')]
        [string]$Name,

        [Parameter(Mandatory, ParameterSetName = 'SecureString', HelpMessage = 'The secret to save.')]
        [ValidateNotNull()]
        [System.Security.SecureString]$SecureString,

        [Parameter(Mandatory, ParameterSetName = 'Credential', HelpMessage = 'The credential to save.')]
        [ValidateNotNull()]
        [System.Management.Automation.PSCredential]$Credential,

        [Parameter(HelpMessage = 'Who can decrypt the secret.')]
        [ValidateSet('CurrentUser', 'LocalMachine')]
        [string]$Scope = 'CurrentUser'
    )

    $path = Get-ModuleSecretPath -ModuleName $ModuleName -Name $Name
    if (-not $PSCmdlet.ShouldProcess("$ModuleName secret '$Name'", 'Save secret')) {
        return
    }

    if ($PSCmdlet.ParameterSetName -eq 'Credential') {
        $type = 'PSCredential'
        $userName = $Credential.UserName
        $plainText = $Credential.GetNetworkCredential().Password
    }
    else {
        $type = 'SecureString'
        $userName = $null
        $plainText = (New-Object System.Net.NetworkCredential -ArgumentList '', $SecureString).Password
    }

    try {
        # An empty secret (for example a credential without a password) is stored as empty
        $protected = ''
        if (-not [string]::IsNullOrEmpty($plainText)) {
            $protected = Protect-ConfigValue -Value $plainText -Scope $Scope -ErrorAction Stop
            if ([string]::IsNullOrEmpty($protected)) {
                throw "The secret '$Name' could not be protected."
            }
        }
    }
    finally {
        $plainText = $null
    }

    $data = @{
        Type    = $type
        Value   = $protected
        Updated = [datetime]::UtcNow.ToString('o', [System.Globalization.CultureInfo]::InvariantCulture)
    }
    if ($userName) {
        $data['UserName'] = $userName
    }
    Write-JsonFile -Path $path -Data $data
}
