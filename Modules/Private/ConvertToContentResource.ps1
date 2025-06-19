<#
.SYNOPSIS
    Converts a hashtable content to a content resource object.

.DESCRIPTION
    The ConvertTo-ContentResource function takes a hashtable representing content and converts it to a
    content resource object based on its type. It supports various resource kinds such as ASIM, Fusion,
    Hunt, MicrosoftSecurityIncidentCreation, MLBehaviorAnalytics, NRT, Parser, Scheduled, and
    ThreatIntelligence. If the content type is not valid, it throws an error.

.PARAMETER Content
    The hashtable representing the content to be converted. This parameter is mandatory.

.PARAMETER Config
    An object representing the configuration for the content. This parameter is mandatory.

.OUTPUTS
    System.Collections.Specialized.OrderedDictionary
    The content resource object.

.EXAMPLE
    PS C:\> $config = [ordered]@{ settings = @{ "workspace" = "SampleWorkspace" } }
    PS C:\> $content = @{ "Type" = "ASIM"; "Data" = "Sample data" }
    PS C:\> ConvertTo-ContentResource -Content $content -Config $config

.EXAMPLE
    PS C:\> $config = [ordered]@{ settings = @{ "workspace" = "SampleWorkspace" } }
    PS C:\> $content = @{ "Type" = "Fusion"; "Data" = "Sample data" }
    PS C:\> ConvertTo-ContentResource -Content $content -Config $config
#>
function ConvertTo-ContentResource {
    [CmdletBinding()]
    [OutputType([System.Collections.Specialized.OrderedDictionary])]
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]
        $Content,

        [Parameter(Mandatory = $true)]
        [object]
        $Config
    )
    Set-StrictMode -Version 3.0
    $resource = $null
    $resourceKind = Get-ContentType -Content $Content
    $validYamlKind = @(
        "AddIncidentTask", # Automation rule of type AddIncidentTask
        "ASIM", # ASIM parser
        "Fusion", # Alert rule
        "Hunt", # Hunting query
        "MicrosoftSecurityIncidentCreation", # Alert rule
        "MLBehaviorAnalytics", # Alert rule
        "ModifyProperties", # Automation rule of type ModifyProperties
        "NRT", # Alert rule
        "Parser", # KQL Function parser
        "RunPlaybook", # Automation rule of type RunPlaybook
        "Scheduled", # Alert rule
        "ThreatIntelligence" # Alert rule
    )
    $validJsonKind = @(
        "Connector", # Data Connector
        "Playbook",
        "QueryPack",
        "Solution", # Sentinel solution
        "Watchlist", # Todo: not sure this will be json, perhaps csv or yaml
        "Workbook"
    )

    if ($resourceKind -in $validYamlKind -or $resourceKind -in $validJsonKind) {
        $resource = Get-ContentObject -Content $Content -Kind $resourceKind -Config $Config
    } else {
        if ([string]::IsNullOrEmpty($resourceKind)) {
            throw "No content type found for the provided content."
        }
        throw "No valid data found for resource of kind '${resourceKind}'."
    }
    return $resource
}