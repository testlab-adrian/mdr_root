<#
.SYNOPSIS
    Retrieves a value from a hashtable based on a specified key and optional sub key, and returns it
    as a tagged hashtable.

.DESCRIPTION
    The Get-ContentKeyTag function takes a hashtable and retrieves a value based on the specified key
    and optional sub key. It then returns the value as a hashtable with a specified tag name. If the
    Clean switch is specified, the value is cleaned by trimming whitespace and removing surrounding
    quotes. If the key or sub key does not exist, it returns an empty hashtable.

.PARAMETER Content
    The hashtable containing the content. This parameter is mandatory.

.PARAMETER Key
    The key to look for in the hashtable. This parameter is mandatory.

.PARAMETER SubKey
    The optional sub key to look for within the value of the specified key. This parameter is optional.

.PARAMETER TagName
    The name to tag the retrieved value with. This parameter is mandatory.

.PARAMETER Clean
    A switch to indicate if the value should be cleaned by trimming whitespace and removing surrounding
    quotes. This parameter is optional.

.OUTPUTS
    System.Collections.Hashtable
    A hashtable containing the tagged value.

.EXAMPLE
    PS C:\> $content = @{ "Key1" = @{ "SubKey1" = " value " }; "Key2" = " value " }
    PS C:\> Get-ContentKeyTag -Content $content -Key "Key1" -SubKey "SubKey1" -TagName "Tag1" -Clean
    @{
        name  = "Tag1"
        value = "value"
    }

.EXAMPLE
    PS C:\> $content = @{ "Key1" = @{ "SubKey1" = " value " }; "Key2" = " value " }
    PS C:\> Get-ContentKeyTag -Content $content -Key "Key2" -TagName "Tag2" -Clean
    @{
        name  = "Tag2"
        value = "value"
    }
#>
function Get-ContentKeyTag {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]
        $Content,

        [Parameter(Mandatory = $true)]
        [string]
        $Key,

        [Parameter(Mandatory = $false)]
        [AllowEmptyString()]
        [string]
        $SubKey = "",

        [Parameter(Mandatory = $true)]
        [string]
        $TagName,

        [Parameter(Mandatory = $false)]
        [switch]
        $Clean
    )
    Set-StrictMode -Version 3.0
    $value = Get-ContentKeyValue -Content $Content -Key $Key -SubKey $SubKey -Clean:$Clean

    if (-not [string]::IsNullOrWhiteSpace($value)) {
        return @{
            name  = $TagName
            value = $value
        }
    }
}