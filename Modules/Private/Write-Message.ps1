<#
.SYNOPSIS
Logs messages.

.DESCRIPTION
The Write-Message function outputs messages based on the given severity.
This ensures that the messages do not interfere with the functional output.

.PARAMETER Message
Required. The message to be logged.

.PARAMETER Severity
Optional. The severity of the message. Can be Debug, Error, Info, Verbose or Warning.
Default is Info.

.EXAMPLE
PS C:\> Write-Message -Message "This is an informational message."
This command logs the specified informational message.

.EXAMPLE
PS C:\> Write-Message -Message "This is a warning message." -Severity Warning
This command logs the specified warning message.
#>
function Write-Message {
    [CmdletBinding()]
    [OutputType([void])]
    param (
        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string]
        $Message,

        [Parameter(Mandatory = $false)]
        [ValidateSet('Debug', 'Error', 'Info', 'Verbose', 'Warning')]
        [string]
        $Severity = "Info"
    )
    Set-StrictMode -Version 3.0
    if ([string]::IsNullOrWhiteSpace($Message)) {
        return
    }
    switch ($Severity) {
        "Error" {
            Write-Error -Message $Message
        }
        "Verbose" {
            Write-Verbose -Message $Message
        }
        "Debug" {
            Write-Debug -Message $Message
        }
        "Warning" {
            Write-Warning -Message $Message
        }
        default {
            Write-Information -MessageData $Message -InformationAction Continue
        }
    }
}
