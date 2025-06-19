<#
.SYNOPSIS
    Reads the content of a file and returns it as a string.

.DESCRIPTION
    The Get-FileContent function reads the entire content of a specified file and returns it as a
    single string. This function uses the .NET System.IO.File::ReadAllText method to read the file
    content.

.PARAMETER FilePath
    The path to the file to be read. This parameter is mandatory.

.OUTPUTS
    System.String
    Returns the content of the file as a string.

.EXAMPLE
    PS C:\> Get-FileContent -FilePath "file.txt"
    Reads the content of the file "file.txt" and returns it as a string.

.NOTES
    This function has no pester test because it is a simple wrapper around the .NET method
#>
function Get-FileContent {
    [CmdletBinding()]
    [OutputType([string])]
    param (
        [Parameter(Mandatory = $true)]
        [string]
        $FilePath
    )
    Set-StrictMode -Version 3.0
    $content = [System.IO.File]::ReadAllText($FilePath)

    return $content
}
