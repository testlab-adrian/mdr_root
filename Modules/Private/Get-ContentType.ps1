<#
.SYNOPSIS
    Determines the content type of a YAML or JSON content object.

.DESCRIPTION
    The Get-ContentType function takes a hashtable representing YAML or JSON content and determines
    its content type based on specific fields and values. It supports various content types such as
    Connector, Scheduled, NRT, MicrosoftSecurityIncidentCreation, Fusion, MLBehaviorAnalytics,
    ThreatIntelligence, Parser, ASIM, and Hunt. If the content type cannot be determined, it returns
    an empty string.

.PARAMETER Content
    The hashtable containing the YAML or JSON content. This parameter is mandatory and allows null,
    empty strings, and empty collections.

.OUTPUTS
    System.String
    The determined content type as a string.

.EXAMPLE
    PS C:\> $content = @{
    >>     kind = "Scheduled"
    >>     description = "Sample description"
    >>     id = "12345"
    >>     name = "SampleName"
    >>     query = "Sample query"
    >>     relevantTechniques = @("T1234")
    >>     severity = "High"
    >>     tactics = @("TA0001")
    >> }
    PS C:\> Get-ContentType -Content $content
    Scheduled

.EXAMPLE
    PS C:\> $content = @{
    >>     kind = "MicrosoftSecurityIncidentCreation"
    >>     id = "12345"
    >>     name = "SampleName"
    >>     productFilter = "SampleProduct"
    >> }
    PS C:\> Get-ContentType -Content $content
    MicrosoftSecurityIncidentCreation

.EXAMPLE
    PS C:\> $content = @{
    >>     Category = "SampleCategory"
    >>     FunctionAlias = "SampleAlias"
    >>     FunctionName = "SampleFunction"
    >>     FunctionQuery = "Sample query"
    >>     id = "12345"
    >> }
    PS C:\> Get-ContentType -Content $content
    Parser
#>
function Get-ContentType {
    [CmdletBinding()]
    [OutputType([string])]
    param (
        [Parameter(Mandatory = $true)]
        [AllowNull()]
        [AllowEmptyString()]
        [AllowEmptyCollection()]
        [object]
        $Content
    )
    Set-StrictMode -Version 3.0
    if ([string]::IsNullOrEmpty($Content)) {
        return ""
    }

    # Todo: Add more content types:
    # AddIncidentTask
    # ModifyProperties
    # Playbook
    # QueryPack
    # Solution
    # Watchlist

    if (
        $Content -is [hashtable] -and
        $Content.ContainsKey("version") -and
        $Content["version"] -match "Notebook\/\d.*\d" -and
        $Content.ContainsKey("items") -and
        $Content.ContainsKey('$schema') -and
        -not ([string]::IsNullOrWhiteSpace($Content['$schema']))
    ) {
        return "Workbook"
    } elseif (
        $Content -is [hashtable] -and
        $Content.ContainsKey("id") -and
        $Content.ContainsKey("displayName") -and
        $Content.ContainsKey("order") -and
        $Content.ContainsKey("triggeringLogic") -and
        $Content.ContainsKey("actions") -and
        $Content["actions"] -is [System.Collections.Generic.List[System.Object]] -and
        $Content["actions"].Count -eq 1 -and
        $Content["actions"][0] -is [hashtable] -and
        $Content["actions"][0].ContainsKey("actionType") -and
        $Content["actions"][0]["actionType"] -eq "RunPlaybook" -and
        -not ([string]::IsNullOrWhiteSpace($Content["id"])) -and
        -not ([string]::IsNullOrWhiteSpace($Content["displayName"]))
    ) {
        return "RunPlaybook" # Self decided RunPlaybook Automation Rule format
    } elseif (
        $Content -is [hashtable] -and
        $Content.ContainsKey("connectivityCriterias") -and
        $Content.ContainsKey("dataTypes") -and
        $Content.ContainsKey("descriptionMarkdown") -and
        $Content.ContainsKey("graphQueries") -and
        $Content.ContainsKey("id") -and
        $Content.ContainsKey("publisher") -and
        $Content.ContainsKey("title") -and
        -not ([string]::IsNullOrWhiteSpace($Content["id"])) -and
        -not ([string]::IsNullOrWhiteSpace($Content["title"]))
    ) {
        return "Connector" # Standard connector format
    } elseif (
        # Required fields specified in https://github.com/Azure/Azure-Sentinel/wiki/Query-Style-Guide
        $Content -is [hashtable] -and
        $Content.ContainsKey("kind") -and
        (
            $Content["kind"] -eq "Scheduled" -or
            $Content["kind"] -eq "NRT"
        ) -and
        $Content.ContainsKey("description") -and
        $Content.ContainsKey("id") -and
        $Content.ContainsKey("name") -and
        $Content.ContainsKey("query") -and
        $Content.ContainsKey("relevantTechniques") -and
        $Content.ContainsKey("severity") -and
        $Content.ContainsKey("tactics") -and
        -not ([string]::IsNullOrWhiteSpace($Content["id"])) -and
        -not ([string]::IsNullOrWhiteSpace($Content["name"]))
    ) {
        return $Content["kind"]
    } elseif (
        $Content -is [hashtable] -and
        $Content.ContainsKey("kind") -and
        $Content["kind"] -eq "MicrosoftSecurityIncidentCreation" -and
        $Content.ContainsKey("id") -and
        $Content.ContainsKey("name") -and
        $Content.ContainsKey("productFilter") -and
        -not ([string]::IsNullOrWhiteSpace($Content["id"])) -and
        -not ([string]::IsNullOrWhiteSpace($Content["name"]))
    ) {
        return $Content["kind"]
    } elseif (
        $Content -is [hashtable] -and
        $Content.ContainsKey("kind") -and
        (
            $Content["kind"] -eq "Fusion" -or
            $Content["kind"] -eq "MLBehaviorAnalytics" -or
            $Content["kind"] -eq "ThreatIntelligence"
        ) -and
        $Content.ContainsKey("id") -and
        $Content.ContainsKey("name") -and
        -not ([string]::IsNullOrWhiteSpace($Content["id"])) -and
        -not ([string]::IsNullOrWhiteSpace($Content["name"]))
    ) {
        return $Content["kind"]
    } elseif (
        # KQL Function parsers
        $Content -is [hashtable] -and
        $Content.ContainsKey("Category") -and
        $Content.ContainsKey("FunctionAlias") -and
        $Content.ContainsKey("FunctionName") -and
        $Content.ContainsKey("FunctionQuery") -and
        $Content.ContainsKey("id") -and
        -not ([string]::IsNullOrWhiteSpace($Content["FunctionName"])) -and
        -not ([string]::IsNullOrWhiteSpace($Content["id"]))
    ) {
        return "Parser"
    } elseif (
        $Content -is [hashtable] -and
        $Content.ContainsKey("Normalization") -and
        $Content["Normalization"].ContainsKey("Schema") -and
        $Content.ContainsKey("Parser") -and
        $Content["Parser"].ContainsKey("Title") -and
        $Content.ContainsKey("ParserName") -and
        $Content.ContainsKey("ParserQuery") -and
        -not ([string]::IsNullOrWhiteSpace($Content["Parser"]["Title"])) -and
        -not ([string]::IsNullOrWhiteSpace($Content["ParserName"]))
    ) {
        return "ASIM"
    } elseif (
        # Required fields specified in https://github.com/Azure/Azure-Sentinel/wiki/Query-Style-Guide
        $Content -is [hashtable] -and
        $Content.ContainsKey("description") -and
        $Content.ContainsKey("id") -and
        $Content.ContainsKey("name") -and
        $Content.ContainsKey("query") -and
        $Content.ContainsKey("tactics") -and
        -not ([string]::IsNullOrWhiteSpace($Content["id"])) -and
        -not ([string]::IsNullOrWhiteSpace($Content["name"]))
    ) {
        return "Hunt"
    }
    return ""
}
