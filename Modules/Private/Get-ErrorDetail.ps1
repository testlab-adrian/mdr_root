<#
.SYNOPSIS
Generates a message from an error record.

.DESCRIPTION
The Get-ErrorDetail function takes an error record as input and generates a message.
The message includes the PositionMessage, if it is available in the error record.
The message is sanitized by removing control characters except new line.

.PARAMETER ErrorRecord
Required. The error record object containing details about the error.

.OUTPUTS
System.String
Returns a error message string with the PositionMessage, if available.

.EXAMPLE
PS C:\> Get-ErrorDetail -ErrorRecord $Error[0]
This command generates a detailed error message from the most recent error record.
#>
function Get-ErrorDetail {
    [CmdletBinding()]
    [OutputType([string])]
    param (
        [Parameter(Mandatory = $true)]
        [System.Object]
        $ErrorRecord
    )
    Set-StrictMode -Version 3.0
    $message = $ErrorRecord.Exception.Message
    if (
        $null -ne $ErrorRecord.InvocationInfo -and
        [bool]$(
            $ErrorRecord.InvocationInfo | Get-Member -Name PositionMessage
        ) -and -not
        [string]::IsNullOrWhiteSpace($ErrorRecord.InvocationInfo.PositionMessage)
    ) {
        $message += [System.Environment]::NewLine
        $message += $ErrorRecord.InvocationInfo.PositionMessage
    }
    return ($message -replace '[\p{C}&&[^\r\n]]', '')
}
