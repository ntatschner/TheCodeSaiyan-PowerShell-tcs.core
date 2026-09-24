---
Module Name: tcs.core
Module Guid: {{ Update Module Guid }}
Download Help Link: {{ Update Download Link }}
Help Version: {{ Update Help Version }}
Locale: {{ Update Locale }}
---

# tcs.core Module
## Description
{{ Fill in the Description }}

## tcs.core Cmdlets
### [Complete-TcsTelemetry](Complete-TcsTelemetry.md)
Completes a run started with Start-TcsTelemetry and sends its telemetry event.

### [ConvertTo-CamelCase](ConvertTo-CamelCase.md)
Converts a string to camelCase format.

### [ConvertTo-HashTable](ConvertTo-HashTable.md)
Converts a PSCustomObject to a hashtable.

### [ConvertTo-KebabCase](ConvertTo-KebabCase.md)
Converts a string to kebab-case format.

### [ConvertTo-PascalCase](ConvertTo-PascalCase.md)
Converts a string to PascalCase format.

### [ConvertTo-QueryString](ConvertTo-QueryString.md)
Converts a hashtable to a URL query string.

### [ConvertTo-SnakeCase](ConvertTo-SnakeCase.md)
Converts a string to snake_case format.

### [Get-HttpErrorDetail](Get-HttpErrorDetail.md)
Returns the HTTP status code, body and Retry-After delay of a failed web request.

### [Get-ModuleConfig](Get-ModuleConfig.md)
Retrieves the configuration for a PowerShell module in the tcs suite.

### [Get-ModuleSecret](Get-ModuleSecret.md)
Reads a secret or credential saved with Set-ModuleSecret.

### [Get-ModuleStatus](Get-ModuleStatus.md)
Checks whether a newer version of a module is available in the PowerShell Gallery.

### [Get-ParameterValues](Get-ParameterValues.md)
Extracts and filters parameter values from PSBoundParameters.

### [Invoke-TcsCommand](Invoke-TcsCommand.md)
Runs the body of a tcs command and records anonymous telemetry for it.

### [Invoke-TelemetryCollection](Invoke-TelemetryCollection.md)
Records anonymous usage telemetry for a command or module load.

### [Invoke-WithRetry](Invoke-WithRetry.md)
Executes a script block with automatic retry logic on failure.

### [New-BasicAuthHeader](New-BasicAuthHeader.md)
Builds an HTTP Basic Authorization header from a credential.

### [New-DynamicParameter](New-DynamicParameter.md)
Creates a dynamic parameter for use in PowerShell functions with DynamicParam blocks.

### [New-TemporaryDirectory](New-TemporaryDirectory.md)
Creates a new temporary directory with an optional name prefix.

### [Protect-ConfigValue](Protect-ConfigValue.md)
Encrypts a string value for secure storage in configuration files.

### [Remove-ModuleSecret](Remove-ModuleSecret.md)
Deletes a secret or credential saved with Set-ModuleSecret.

### [Set-ModuleConfig](Set-ModuleConfig.md)
Sets or updates configuration values for a module in the tcs suite.

### [Set-ModuleSecret](Set-ModuleSecret.md)
Saves a secret or credential for a tcs module, encrypted for the current user.

### [Start-TcsTelemetry](Start-TcsTelemetry.md)
Starts timing one run of a command for telemetry and returns a token for Complete-TcsTelemetry.

### [Test-IsElevated](Test-IsElevated.md)
Tests whether the current PowerShell session is running with elevated (administrator/root) privileges.

### [Unprotect-ConfigValue](Unprotect-ConfigValue.md)
Decrypts a value previously protected by Protect-ConfigValue.

### [Write-Log](Write-Log.md)
Writes a structured log message to the console and/or a log file.

