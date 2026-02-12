<#
.SYNOPSIS
    Creates a new temporary directory with an optional name prefix.

.DESCRIPTION
    The New-TemporaryDirectory function creates a uniquely named temporary directory under
    the system temp path or a specified base path. The directory name is composed of the
    given prefix followed by the first 8 characters of a new GUID, ensuring uniqueness.
    The function returns the DirectoryInfo object for the created directory.

.PARAMETER Prefix
    A prefix string for the temporary directory name. Defaults to 'tcs'. The final directory
    name follows the pattern '{Prefix}_{first8-guid-chars}'.

.PARAMETER BasePath
    An optional base directory path under which the temporary directory is created. Defaults
    to the system temporary path returned by [System.IO.Path]::GetTempPath().

.INPUTS
    None
    This function does not accept pipeline input.

.OUTPUTS
    System.IO.DirectoryInfo
    Returns the DirectoryInfo object representing the newly created temporary directory.

.EXAMPLE
    New-TemporaryDirectory

    Creates a directory like 'C:\Users\<user>\AppData\Local\Temp\tcs_a1b2c3d4' and returns
    its DirectoryInfo object.

.EXAMPLE
    New-TemporaryDirectory -Prefix "build" -BasePath "D:\Staging"

    Creates a directory like 'D:\Staging\build_e5f6a7b8' and returns its DirectoryInfo object.

.EXAMPLE
    $tmpDir = New-TemporaryDirectory -Prefix "test"
    Set-Location $tmpDir.FullName

    Creates a temporary directory with a 'test' prefix and changes to it.

.NOTES
    Author: Nigel Tatschner
    Company: TheCodeSaiyan
    Version: 0.2.0

    This function is part of the tcs.core module and provides a convenient way to create
    uniquely named temporary directories for build artifacts, test isolation, or other
    transient file operations.

.LINK
    https://ntatschner.github.io/TheCodeSaiyan-PowerShell-tcs.core/
#>
function New-TemporaryDirectory {
    [CmdletBinding()]
    [OutputType([System.IO.DirectoryInfo])]
    param(
        [Parameter(HelpMessage = "Prefix string for the temporary directory name.")]
        [string]$Prefix = 'tcs',

        [Parameter(HelpMessage = "Base directory path for the temporary directory.")]
        [string]$BasePath
    )

    if ([string]::IsNullOrWhiteSpace($BasePath)) {
        $BasePath = [System.IO.Path]::GetTempPath()
    }

    $guidSegment = (New-Guid).ToString('N').Substring(0, 8)
    $directoryName = "${Prefix}_${guidSegment}"
    $fullPath = Join-Path -Path $BasePath -ChildPath $directoryName

    $directory = New-Item -Path $fullPath -ItemType Directory -Force
    return $directory
}
