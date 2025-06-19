<#
.SYNOPSIS
    Converts a time duration string to ISO 8601 format.

.DESCRIPTION
    The ConvertTo-ISO8601 function takes a string representing a time duration and converts it to the
    ISO 8601 duration format. It supports durations in hours (H), minutes (M), and days (D). If the
    input value does not match any known pattern, it returns the original value.

.PARAMETER Value
    The time duration string to be converted. This parameter is mandatory.

.OUTPUTS
    System.String
    The ISO 8601 formatted duration string.

.EXAMPLE
    PS C:\> ConvertTo-ISO8601 -Value "5H"
    PT5H

.EXAMPLE
    PS C:\> ConvertTo-ISO8601 -Value "10M"
    PT10M

.EXAMPLE
    PS C:\> ConvertTo-ISO8601 -Value "3D"
    P3D

.EXAMPLE
    PS C:\> ConvertTo-ISO8601 -Value "2W"
    2W
#>
function ConvertTo-ISO8601 {
    [CmdletBinding()]
    [OutputType([string])]
    param (
        [Parameter(Mandatory = $true)]
        [string]
        $Value
    )
    Set-StrictMode -Version 3.0
    $Value = $Value.ToUpper()
    switch -RegEx ($Value) {
        '^\d+[HM]$' { return 'PT{0}' -f $Value }
        '^\d+[D]$' { return 'P{0}' -f $Value }
    }
    return $Value
}