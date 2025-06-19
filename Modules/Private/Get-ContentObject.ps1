<#
.SYNOPSIS
    Retrieves a content object based on the specified kind.

.DESCRIPTION
    The Get-ContentObject function takes a hashtable representing content and a kind string, and
    retrieves a content object based on the specified kind. It supports various kinds such as ASIM,
    Hunt, and Parser. The function returns an ordered dictionary representing the content object.

.PARAMETER Content
    The hashtable containing the content. This parameter is mandatory.

.PARAMETER Kind
    The kind of content to retrieve. This parameter is mandatory.

.PARAMETER Config
    An object representing the configuration for the content. This parameter is mandatory.

.OUTPUTS
    System.Collections.Specialized.OrderedDictionary
    The content object.

.EXAMPLE
    PS C:\> $config = [ordered]@{ settings = @{ "workspace" = "SampleWorkspace" } }
    PS C:\> $content = @{ "ParserName" = "SampleParser"; "id" = "12345"; "FunctionName" = "SampleFunction" }
    PS C:\> Get-ContentObject -Content $content -Kind "ASIM" -Config $config

.EXAMPLE
    PS C:\> $config = [ordered]@{ settings = @{ "workspace" = "SampleWorkspace" } }
    PS C:\> $content = @{ "ParserName" = "SampleParser"; "id" = "12345"; "FunctionName" = "SampleFunction" }
    PS C:\> Get-ContentObject -Content $content -Kind "Hunt" -Config $config

.EXAMPLE
    PS C:\> $config = [ordered]@{ settings = @{ "workspace" = "SampleWorkspace" } }
    PS C:\> $content = @{ "ParserName" = "SampleParser"; "id" = "12345"; "FunctionName" = "SampleFunction" }
    PS C:\> Get-ContentObject -Content $content -Kind "Parser" -Config $config
#>
function Get-ContentObject {
    [CmdletBinding()]
    [OutputType([System.Collections.Specialized.OrderedDictionary])]
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]
        $Content,

        [Parameter(Mandatory = $true)]
        [string]
        $Kind,

        [Parameter(Mandatory = $true)]
        [object]
        $Config
    )
    Set-StrictMode -Version 3.0
    $alertRuleKinds = @(
        "Fusion",
        "MicrosoftSecurityIncidentCreation",
        "MLBehaviorAnalytics",
        "NRT",
        "Scheduled",
        "ThreatIntelligence"
    )

    if ($Kind -in @("ASIM", "Hunt", "Parser")) {
        $name = switch ($Kind) {
            "ASIM" { $Content["ParserName"] }
            "Hunt" { $Content["id"] }
            "Parser" { $Content["FunctionName"] }
        }
        return [ordered]@{
            type       = "Microsoft.OperationalInsights/workspaces/savedSearches"
            apiVersion = "2023-09-01"
            name       = "[concat(parameters('workspace'), '/${name}')]"
            properties = Get-ContentPropertiesObject -Content $Content -Kind $Kind -Config $Config
        }
    } elseif ($Kind -in @("AddIncidentTask", "ModifyProperties", "RunPlaybook")) {
        return [ordered]@{
            type       = "Microsoft.SecurityInsights/automationRules"
            apiVersion = "2025-03-01"
            name       = $Content["id"]
            scope      = "[concat('Microsoft.OperationalInsights/workspaces/', parameters('workspace'))]"
            properties = Get-ContentPropertiesObject -Content $Content -Kind $Kind -Config $Config
        }
    #} elseif ($Kind -eq "Connector") { # Todo: Must first be implemented in Get-ContentPropertiesObject
    #    $isStatic = $false
    #    $list = Get-ContentKeyValue -Content $Config -Key "contentSettings" -SubKey "StaticConnectors"
    #    if ($list -is [array]) {
    #        $isStatic = [bool]($list | Where-Object { $_ -eq $Content["id"] })
    #    }
    #    return [ordered]@{
    #        type       = "Microsoft.OperationalInsights/workspaces/providers/dataConnectors"
    #        apiVersion = "2021-03-01-preview"
    #        name       = "[concat(parameters('workspace'), '/Microsoft.SecurityInsights/$($Content["id"])')]"
    #        kind       = $isStatic ? "StaticUI" : "GenericUI"
    #        properties = Get-ContentPropertiesObject -Content $Content -Kind $Kind -Config $Config
    #    }
    } elseif ($Kind -in $alertRuleKinds) {
        return [ordered]@{
            type       = "Microsoft.OperationalInsights/workspaces/providers/alertRules"
            apiVersion = "2024-04-01-preview"
            name       = "[concat(parameters('workspace'), '/Microsoft.SecurityInsights/$($Content["id"])')]"
            kind       = $Kind
            properties = Get-ContentPropertiesObject -Content $Content -Kind $Kind -Config $Config
        }
    } else {
        throw "$Kind content is not yet supported."
    }
}
