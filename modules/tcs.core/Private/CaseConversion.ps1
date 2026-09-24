<#
.SYNOPSIS
    Internal helpers shared by ConvertTo-CamelCase, ConvertTo-PascalCase, ConvertTo-SnakeCase
    and ConvertTo-KebabCase.

.NOTES
    Private helpers for the tcs.core module. Unicode categories (\p{Lu}, \p{Ll}, \p{Nd}) are
    used so that letters outside A-Z, such as 'Ä' or 'É', split words too.
#>

# Word boundaries: spaces, underscores and hyphens; lower -> upper ('helloWorld');
# the last capital of an acronym before a capitalised word ('XMLHttp'); and digit -> upper
# ('Version2Update', 'user2FA'). Digits stay with the word before them ('utf8', 'Version2').
$script:CaseWordPattern = '[\s_\-]+|(?<=\p{Ll})(?=\p{Lu})|(?<=\p{Lu})(?=\p{Lu}\p{Ll})|(?<=\p{Nd})(?=\p{Lu})'

function Split-CaseWord {
    <#
    .SYNOPSIS
        Splits an identifier or phrase into words.
    #>
    [CmdletBinding()]
    [OutputType([string[]])]
    param(
        [AllowEmptyString()]
        [string]$Value
    )

    # @() keeps a single word as an array instead of a string
    return , @([regex]::Split($Value, $script:CaseWordPattern) | Where-Object { $_ -ne '' })
}

function Test-CaseAcronym {
    <#
    .SYNOPSIS
        Returns $true for an all-capitals word with at least two capital letters, such as
        'XML', 'FA' or 'HTML5'.
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [AllowEmptyString()]
        [string]$Word
    )

    return ($Word -cmatch '^[\p{Lu}\p{Nd}]+$' -and ([regex]::Matches($Word, '\p{Lu}')).Count -ge 2)
}

function ConvertTo-CapitalisedWord {
    <#
    .SYNOPSIS
        Capitalises a word ('hello' -> 'Hello'), or keeps an acronym as it is with -PreserveAcronyms.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [AllowEmptyString()]
        [string]$Word,

        [switch]$PreserveAcronyms
    )

    if ($Word.Length -eq 0) {
        return $Word
    }
    if ($PreserveAcronyms -and (Test-CaseAcronym -Word $Word)) {
        return $Word
    }
    return $Word.Substring(0, 1).ToUpperInvariant() + $Word.Substring(1).ToLowerInvariant()
}
