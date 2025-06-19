<#
.SYNOPSIS
    Cleans a string by trimming whitespace and removing surrounding quotes.

.DESCRIPTION
    The Get-CleanString function takes a string value, trims any leading or trailing whitespace, and
    removes any surrounding single or double quotes. If the input string is empty or null, it returns
    the original value.

.PARAMETER Value
    The string value to be cleaned. This parameter is mandatory and allows empty strings.

.OUTPUTS
    System.String
    The cleaned string.

.EXAMPLE
    PS C:\> Get-CleanString -Value " 'example' "
    example

.EXAMPLE
    PS C:\> Get-CleanString -Value ' "example" '
    example

.EXAMPLE
    PS C:\> Get-CleanString -Value "example"
    example

.EXAMPLE
    PS C:\> Get-CleanString -Value ""
    (empty string)
#>
function Get-CleanString {
    [CmdletBinding()]
    [OutputType([string])]
    param (
        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string]
        $Value
    )
    Set-StrictMode -Version 3.0
    $Value = $Value.Trim()
    if (-not [string]::IsNullOrWhiteSpace($Value)) {
        if ($Value.StartsWith("'") -or $Value.StartsWith('"')) {
            $Value = $Value.Substring(1, $Value.Length - 1).Trim()
        }
        if ($Value.EndsWith("'") -or $Value.EndsWith('"')) {
            $Value = $Value.Substring(0, $Value.Length - 1).Trim()
        }
    }
    return $Value
}