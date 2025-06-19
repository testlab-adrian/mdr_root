<#
.SYNOPSIS
    Retrieves a value from a hashtable based on a specified key and optional sub key.

.DESCRIPTION
    The Get-ContentKeyValue function takes a hashtable and retrieves a value based on the specified key
    and optional sub key. If the Clean switch is specified, the value is cleaned by trimming whitespace
    and removing surrounding quotes. If the key or sub key does not exist, it returns an empty string.

.PARAMETER Content
    The hashtable containing the content. This parameter is mandatory.

.PARAMETER Key
    The key to look for in the hashtable. This parameter is mandatory.

.PARAMETER SubKey
    The optional sub key to look for within the value of the specified key. This parameter is optional.

.PARAMETER Clean
    A switch to indicate if the value should be cleaned by trimming whitespace and removing surrounding
    quotes. This parameter is optional.

.OUTPUTS
    System.String
    The retrieved and optionally cleaned value.

.EXAMPLE
    PS C:\> $content = @{ "Key1" = @{ "SubKey1" = " value " }; "Key2" = " value " }
    PS C:\> Get-ContentKeyValue -Content $content -Key "Key1" -SubKey "SubKey1" -Clean
    value

.EXAMPLE
    PS C:\> $content = @{ "Key1" = @{ "SubKey1" = " value " }; "Key2" = " value " }
    PS C:\> Get-ContentKeyValue -Content $content -Key "Key2" -Clean
    value

.EXAMPLE
    PS C:\> $content = @{ "Key1" = @{ "SubKey1" = " value " }; "Key2" = " value " }
    PS C:\> Get-ContentKeyValue -Content $content -Key "Key2"
    value
#>
function Get-ContentKeyValue {
    [CmdletBinding()]
    [OutputType([object])]
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]
        $Content,

        [Parameter(Mandatory = $true)]
        [string]
        $Key,

        [Parameter(Mandatory = $false)]
        [string]
        $SubKey = "",

        [Parameter(Mandatory = $false)]
        [switch]
        $Clean
    )
    Set-StrictMode -Version 3.0
    $value = ""
    if ($Content.ContainsKey($Key)) {
        if ([string]::IsNullOrWhiteSpace($SubKey)) {
            $value = $Clean ? (Get-CleanString -Value $Content[$Key]) : $Content[$Key]
        } else {
            if ($Content[$Key].ContainsKey($SubKey)) {
                $value = $Clean ? (Get-CleanString -Value $Content[$Key][$SubKey]) : $Content[$Key][$SubKey]
            }
        }
    }

    if ($value -is [string]) {
        return $value.Trim()
    } else {
        return $value
    }
}