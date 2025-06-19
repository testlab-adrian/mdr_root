<#
.SYNOPSIS
    Reads a JSON file and converts it to a PowerShell object.

.DESCRIPTION
    The Read-JsonFile function reads the content of a specified JSON file and converts it to a
    hashtable. This function is useful for reading configuration files and other structured data
    stored in JSON format.

.PARAMETER FilePath
    The full path to the JSON file to be read. This parameter is mandatory.

.PARAMETER File
    The name of the JSON file to be read. This parameter is optional. If not specified, the file
    defaults to the value of the FilePath parameter.

.PARAMETER WarningOnly
    A switch to indicate if the function should only give a warning message if it fails to read
    the JSON file. This parameter is optional.

.OUTPUTS
    System.Object
    The PowerShell object representing the JSON content.

.EXAMPLE
    PS C:\> $config = Read-JsonFile -FilePath "C:\path\to\config.json" -File "config.json"
    Reads the content of the specified JSON file and converts it to a PowerShell object.
#>
function Read-JsonFile {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param (
        [Parameter(Mandatory = $true)]
        [string]
        $FilePath,

        [Parameter(Mandatory = $false)]
        [string]
        $File = $FilePath,

        [Parameter(Mandatory = $false)]
        [switch]
        $WarningOnly
    )
    Set-StrictMode -Version 3.0
    $output = @{}
    try {
        $fullPath = Resolve-Path -LiteralPath $FilePath -ErrorAction SilentlyContinue
        if ([string]::IsNullOrWhiteSpace($fullPath)) {
            if ($WarningOnly) {
                Write-Message -Severity Warning -Message "Unable to resolve FilePath: ${FilePath}"
                return $output
            } else {
                throw "Unable to resolve FilePath."
            }
        }
        if (-not (Test-Path -LiteralPath $fullPath -PathType Leaf -ErrorAction SilentlyContinue)) {
            if ($WarningOnly) {
                Write-Message -Severity Warning -Message "The file '${File}' does not exist."
                return $output
            } else {
                throw "The file does not exist."
            }
        }
        $output = Get-FileContent -FilePath $fullPath | ConvertFrom-Json -AsHashtable -ErrorAction Stop
    } catch {
        if ($WarningOnly) {
            $message = "Failed to read JSON file '${File}'. Working directory is '${PWD}'."
            $message += [System.Environment]::NewLine
            $message += Get-ErrorDetail -ErrorRecord $_
            Write-Message -Severity Warning -Message $message
        } else {
            throw "Failed to read JSON file '${File}'. $_"
        }
    }
    return $output
}
