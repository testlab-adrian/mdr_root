<#
.SYNOPSIS
    Reads a YAML file and converts it to a PowerShell object.

.DESCRIPTION
    The Read-YamlFile function reads the content of a specified YAML file and converts it to a
    hashtable or to an ordered dictionary if the Ordered switch is specified. This function is
    useful for reading configuration files and other structured data stored in YAML format.

.PARAMETER FilePath
    The full path to the YAML file to be read. This parameter is mandatory.

.PARAMETER File
    The name of the YAML file to be read. This parameter is optional. If not specified, the file
    defaults to the value of the FilePath parameter.

.PARAMETER Ordered
    A switch to indicate if the YAML content should be converted to an ordered dictionary. This
    parameter is optional.

.PARAMETER WarningOnly
    A switch to indicate if the function should only give a warning message if it fails to read
    the YAML file. This parameter is optional.

.OUTPUTS
    System.Object
    The PowerShell object representing the YAML content.

.EXAMPLE
    PS C:\> $config = Read-YamlFile -FilePath "C:\path\to\config.yaml" -File "config.yaml"
    Reads the content of the specified YAML file and converts it to a PowerShell object.

.EXAMPLE
    PS C:\> $config = Read-YamlFile -FilePath "C:\path\to\config.yaml" -File "config.yaml" -Ordered
    Reads the content of the specified YAML file and converts it to an ordered dictionary.
#>
function Read-YamlFile {
    [CmdletBinding()]
    [OutputType([object])]
    param (
        [Parameter(Mandatory = $true)]
        [string]
        $FilePath,

        [Parameter(Mandatory = $false)]
        [string]
        $File = $FilePath,

        [Parameter(Mandatory = $false)]
        [switch]
        $Ordered,

        [Parameter(Mandatory = $false)]
        [switch]
        $WarningOnly
    )
    Set-StrictMode -Version 3.0
    try {
        $fullPath = Resolve-Path -LiteralPath $FilePath -ErrorAction SilentlyContinue
        if ([string]::IsNullOrWhiteSpace($fullPath)) {
            if ($WarningOnly) {
                Write-Message -Severity Warning -Message "Unable to resolve FilePath: ${FilePath}"
                return
            } else {
                throw "Unable to resolve FilePath."
            }
        }
        if (-not (Test-Path -LiteralPath $fullPath -PathType Leaf -ErrorAction SilentlyContinue)) {
            if ($WarningOnly) {
                Write-Message -Severity Warning -Message "The file '${File}' does not exist."
                return
            } else {
                throw "The file does not exist."
            }
        }
        return Get-FileContent -FilePath $fullPath | ConvertFrom-Yaml -Ordered:$Ordered
    } catch {
        if ($WarningOnly) {
            $message = "Failed to read YAML file '${File}'. Working directory is '${PWD}'."
            $message += [System.Environment]::NewLine
            $message += Get-ErrorDetail -ErrorRecord $_
            Write-Message -Severity Warning -Message $message
        } else {
            throw "Failed to read YAML file '${File}'. $_"
        }
    }
}
