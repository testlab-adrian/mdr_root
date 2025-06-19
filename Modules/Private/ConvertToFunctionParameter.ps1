<#
.SYNOPSIS
    Converts objects to a function parameter string.

.DESCRIPTION
    The ConvertTo-FunctionParameter function takes an array of objects and converts them to a string
    representing function parameters. The objects are of type hashtable with "Name" and "Type" keys,
    and optionally a "Default" key. If the object is a string, it is trimmed and added to the result.
    The function supports pipeline input.

.PARAMETER Object
    The array of objects to be converted. This parameter is mandatory and accepts pipeline input.

.OUTPUTS
    System.String
    A string representing the function parameters.

.EXAMPLE
    PS C:\> $params = @(
    >>     @{ Name = "param1"; Type = "string"; Default = "value1" },
    >>     @{ Name = "param2"; Type = "int" }
    >> )
    PS C:\> ConvertTo-FunctionParameter -Object $params
    param1:string='value1',param2:int

.EXAMPLE
    PS C:\> $params = @("param1:string", "param2:int")
    PS C:\> ConvertTo-FunctionParameter -Object $params
    param1:string,param2:int
#>
function ConvertTo-FunctionParameter {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory, Position = 0, ValueFromPipeline)]
        [object[]]
        $Object
    )
    begin {
        Set-StrictMode -Version 3.0
        $data = @()
    }
    process {
        foreach ($item in $Object) {
            if (
                $item -is [hashtable] -and
                $item.ContainsKey("Name") -and
                $item.ContainsKey("Type")
            ) {
                $name = $item["Name"].Trim()
                $type = $item["Type"].Trim()
                if ($item["Type"].StartsWith("table:")) {
                    $data += "{0}:{1}" -f $name, $type.Split(":")[-1]
                } elseif (
                    $item.ContainsKey("Default") -and
                    $null -ne $item["Default"]
                ) {
                    $default = $item["Default"]
                    if ($type -eq "string") {
                        $default = "'$($default.Trim())'"
                    }
                    $data += "{0}:{1}={2}" -f $name, $type, $default
                } else {
                    $data += "{0}:{1}" -f $name, $type
                }
            } elseif ($item -is [string]) {
                $data += $item.Trim()
            }
        }
    }
    end {
        return $data -join ","
    }
}