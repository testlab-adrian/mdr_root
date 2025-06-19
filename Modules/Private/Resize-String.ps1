<#
.SYNOPSIS
Resizes a string to a specified maximum length and appends an ellipsis ("…") if truncated.

.DESCRIPTION
The Resize-String function takes a string and a maximum length as input. If the string exceeds the
specified maximum length, it truncates the string to the maximum length minus one and appends an
ellipsis ("…"). If the string does not exceed the maximum length, it returns the original string.

.PARAMETER String
Required. The string to be resized.

.PARAMETER Length
Optional. The maximum length of the string. The default value is 70.

.OUTPUTS
System.String
Returns the resized string with an ellipsis if truncated, or the original string if not truncated.

.EXAMPLE
PS C:\> Resize-String -String "This is a very long string that needs to be truncated." -Length 30
This command resizes the input string to a maximum length of 30 characters and appends an ellipsis
if truncated.
#>
function Resize-String {
    [CmdletBinding()]
    [OutputType([string])]
    param (
        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string]
        $String,

        [Parameter(Mandatory = $false)]
        [int]
        $Length = 70
    )
    Set-StrictMode -Version 3.0
    if ($String.Length -gt $Length) {
        return $String.Substring(0, $Length - 1) + "…"
    } else {
        return $String
    }
}
