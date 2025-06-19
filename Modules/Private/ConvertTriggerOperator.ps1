<#
.SYNOPSIS
    Converts a trigger operator abbreviation to its full name.

.DESCRIPTION
    The Convert-TriggerOperator function takes a string value representing a trigger operator abbreviation
    and converts it to its full name. If the input value is already a full name, it returns the same value.
    If the input value does not match any known operator, it defaults to "GreaterThan".

.PARAMETER Value
    The trigger operator abbreviation or full name to be converted. This parameter is mandatory.

.OUTPUTS
    System.String
    The full name of the trigger operator.

.EXAMPLE
    PS C:\> Convert-TriggerOperator -Value "lt"
    LessThan

.EXAMPLE
    PS C:\> Convert-TriggerOperator -Value "eq"
    Equal

.EXAMPLE
    PS C:\> Convert-TriggerOperator -Value "ne"
    NotEqual

.EXAMPLE
    PS C:\> Convert-TriggerOperator -Value "GreaterThan"
    GreaterThan
#>
function Convert-TriggerOperator {
    [CmdletBinding()]
    [OutputType([string])]
    param (
        [Parameter(Mandatory = $true)]
        [string]
        $Value
    )
    Set-StrictMode -Version 3.0
    $Value = $Value.Trim()
    switch ($Value) {
        "lt" { return "LessThan" }
        "eq" { return "Equal" }
        "ne" { return "NotEqual" }
        "LessThan" { return $Value }
        "Equal" { return $Value }
        "NotEqual" { return $Value }
    }
    return "GreaterThan"
}