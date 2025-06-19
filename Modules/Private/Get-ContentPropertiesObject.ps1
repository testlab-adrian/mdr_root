
<#
.SYNOPSIS
    Retrieves a content properties object based on the specified kind.

.DESCRIPTION
    The Get-ContentPropertiesObject function takes a hashtable representing content and a kind string,
    and retrieves a content properties object based on the specified kind. It supports various kinds
    such as ASIM, Hunt, Parser, Fusion, MicrosoftSecurityIncidentCreation, NRT, and Scheduled. The
    function returns an ordered dictionary representing the content properties object.

.PARAMETER Content
    The hashtable containing the content. This parameter is mandatory.

.PARAMETER Kind
    The kind of content to retrieve. This parameter is mandatory.

.PARAMETER Config
    An object representing the configuration for the content. This parameter is mandatory.

.OUTPUTS
    System.Collections.Specialized.OrderedDictionary
    The content properties object.

.EXAMPLE
    PS C:\> $config = [ordered]@{ settings = @{ "workspace" = "SampleWorkspace" } }
    PS C:\> $content = @{ "ParserName" = "SampleParser"; "id" = "12345"; "FunctionName" = "SampleFunction" }
    PS C:\> Get-ContentPropertiesObject -Content $content -Kind "ASIM" -Config $config

.EXAMPLE
    PS C:\> $config = [ordered]@{ settings = @{ "workspace" = "SampleWorkspace" } }
    PS C:\> $content = @{ "ParserName" = "SampleParser"; "id" = "12345"; "FunctionName" = "SampleFunction" }
    PS C:\> Get-ContentPropertiesObject -Content $content -Kind "Hunt" -Config $config

.EXAMPLE
    PS C:\> $config = [ordered]@{ settings = @{ "workspace" = "SampleWorkspace" } }
    PS C:\> $content = @{ "ParserName" = "SampleParser"; "id" = "12345"; "FunctionName" = "SampleFunction" }
    PS C:\> Get-ContentPropertiesObject -Content $content -Kind "Parser" -Config $config
#>
function Get-ContentPropertiesObject {
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
    $enabled = $Content.ContainsKey("enabled") ? $Content["enabled"] : $true
    $tags = @()
    $template = Get-ContentKeyValue -Content $Content -Key "alertRuleTemplateName"
    switch ($Kind) {
        "RunPlaybook" {
            $ruleId = $Content["id"]
            $automationResourceGroup = ""
            $automationLinks = ""
            $customer = ""
            if (
                $Config -is [ordered] -and
                $Config.Keys -contains "settings"
            ) {
                if (
                    $Config["settings"] -is [ordered] -and
                    $Config["settings"].Keys -contains "automation-resource-group"
                ) {
                    $automationResourceGroup = $Config["settings"]["automation-resource-group"]
                } else {
                    Write-Message -Severity Warning -Message "Unable to find automation resource group in library file Content/settings.json."
                }
                if (
                    $Config["settings"] -is [ordered] -and
                    $Config["settings"].Keys -contains "customer"
                ) {
                    $customer = $Config["settings"]["customer"]
                } else {
                    Write-Message -Severity Warning -Message "Unable to find customer in library file Content/settings.json."
                }
            } else {
                if ([string]::IsNullOrWhiteSpace($Config)) {
                    Write-Message -Severity Warning -Message "No config was found."
                } else {
                    Write-Message -Severity Warning -Message "Expected config to be a ordered dictionary but it is of type $($Config.GetType().Name)."
                }
            }
            if (
                $Config -is [ordered] -and
                $Config.Keys -contains "contentSettings"
            ) {
                if (
                    $Config["contentSettings"] -is [hashtable] -and
                    $Config["contentSettings"].ContainsKey("ContentLinks")
                ) {
                    $contentLinks = $Config["contentSettings"]["ContentLinks"]
                    if (
                        $contentLinks -is [hashtable] -and
                        $contentLinks.ContainsKey($Kind)
                    ) {
                        $automationLinks = $contentLinks[$Kind]
                    } else {
                        Write-Message -Severity Warning -Message "Unable to find ${Kind} links in library file Content/settings.json."
                    }
                } else {
                    Write-Message -Severity Warning -Message "Unable to find content links in library file Content/settings.json."
                }
            } else {
                Write-Message -Severity Warning -Message "Unable to find content settings in library file Content/settings.json. Config type is $($Config.GetType().Name)."
            }
            if (
                $automationLinks -is [hashtable] -and
                $automationLinks.ContainsKey($ruleId)
            ) {
                $ruleName = "${customer}-$($automationLinks[$ruleId])"
                return [ordered]@{
                    displayName     = $Content["displayName"]
                    order           = $Content["order"]
                    triggeringLogic = $Content["triggeringLogic"]
                    actions         = [ordered]@{
                        actionType          = $Kind
                        actionConfiguration = [ordered]@{
                            logicAppResourceId = "[resourceId('${automationResourceGroup}', 'Microsoft.Logic/workflows', '${ruleName}')]"
                            tenantId           = "[subscription().tenantId]"
                        }
                    }
                }
            } else {
                if ($automationLinks -is [hashtable]) {
                    $formattedLinks = $automationLinks.GetEnumerator() | ForEach-Object {
                        "{0}: {1}" -f $_.Key, $_.Value
                    }
                    Write-Message -Severity Warning -Message "Found the following ContentLinks for ${Kind}:"
                    Write-Message -Severity Warning -Message $formattedLinks
                } elseif ([string]::IsNullOrWhiteSpace($automationLinks)) {
                    Write-Message -Severity Warning -Message "Unable to find any ContentLinks for ${Kind} in library file Content/settings.json."
                } elseif ($automationLinks -is [string]) {
                    Write-Message -Severity Warning -Message "Expected ${Kind} links to be a hashtable type but it is a string: ${automationLinks}."
                } else {
                    Write-Message -Severity Warning -Message "Expected ${Kind} links to be a hashtable type but it is $($automationLinks.GetType().Name)."
                }
                throw "No link to playbook found for Automation rule with id '${ruleId}' in library file Content/settings.json."
            }
        }
        "ASIM" {
            $parserParams = Get-ContentKeyValue -Content $Content -Key "ParserParams"
            $tags += Get-ContentKeyTag -Content $Content -Key "Description" -TagName "description" -Clean
            $tags += Get-ContentKeyTag -Content $Content -Key "Parser" -SubKey "Version" -TagName "version" -Clean
            $tags += Get-ContentKeyTag -Content $Content -Key "Product" -SubKey "Name"  -TagName "product"
            $tags += Get-ContentKeyTag -Content $Content -Key "Normalization" -SubKey "Schema" -TagName "schema"
            $tags += Get-ContentKeyTag -Content $Content -Key "Normalization" -SubKey "Version" -TagName "schema_version"
            return [ordered]@{
                category           = "ASIM"
                displayName        = $Content["Parser"]["Title"]
                eTag               = "*"
                functionAlias      = $Content["ParserName"]
                functionParameters = $parserParams ? (ConvertTo-FunctionParameter -Object $parserParams) : ""
                query              = $Content["ParserQuery"]
                tags               = $tags | Where-Object { $null -ne $_ }
                version            = 2
            }
        }
        "Hunt" {
            $tags += Get-ContentKeyTag -Content $Content -Key "description" -TagName "description" -Clean
            $tags += Get-ContentKeyTag -Content $Content -Key "id" -TagName "id"
            $tags += Get-ContentKeyTag -Content $Content -Key "severity" -TagName "severity"
            $tags += Get-ContentKeyTag -Content $Content -Key "version" -TagName "version" -Clean
            foreach ($key in @("tactics", "relevantTechniques")) {
                $value = Get-ContentKeyValue -Content $Content -Key $key
                if ($value -is [array]) {
                    $value = $value -join ","
                }
                if (-not ([string]::IsNullOrWhiteSpace($value))) {
                    $tags += @{
                        name  = $key
                        value = $value -replace " ", ""
                    }
                }
            }
            return [ordered]@{
                category    = "Hunting Queries"
                displayName = $Content["name"]
                eTag        = "*"
                query       = $Content["query"]
                tags        = $tags | Where-Object { $null -ne $_ }
                version     = 2
            }
        }
        "Parser" {
            $parserParams = Get-ContentKeyValue -Content $Content -Key "FunctionParams"
            $name = Get-ContentKeyValue -Content $Content -Key "Function" -SubKey "Title" -Clean
            $tags += Get-ContentKeyTag -Content $Content -Key "Function" -SubKey "Version" -TagName "version" -Clean
            $tags += Get-ContentKeyTag -Content $Content -Key "id" -TagName "id"
            $tags += @{
                name  = "description"
                value = $name
            }
            return [ordered]@{
                category           = $Content["Category"]
                displayName        = $name ? $name : $Content["FunctionName"]
                eTag               = "*"
                functionAlias      = $Content["FunctionAlias"]
                functionParameters = $parserParams ? (ConvertTo-FunctionParameter -Object $parserParams) : ""
                query              = $Content["FunctionQuery"]
                tags               = $tags | Where-Object { $null -ne $_ }
                version            = 2
            }
        }
        "Fusion" {
            $properties = [ordered]@{
                alertRuleTemplateName = $template ? $template : $Content["id"]
                enabled               = $enabled
            }
            $optionalFields = @( "scenarioExclusionPatterns", "sourceSettings" )
            foreach ($key in $optionalFields) {
                if ($Content.ContainsKey($key)) {
                    $properties.Add($key, @($Content[$key]))
                }
            }
            return $properties
        }
        "MicrosoftSecurityIncidentCreation" {
            $properties = [ordered]@{
                alertRuleTemplateName = $template ? $template : $Content["id"]
                description           = $Content.ContainsKey("description") ? (Get-CleanString -Value $Content.description) : ""
                displayName           = $Content["name"]
                enabled               = $enabled
                productFilter         = $Content["productFilter"]
            }
            $optionalFields = @( "displayNamesExcludeFilter", "displayNamesFilter", "severitiesFilter" )
            foreach ($key in $optionalFields) {
                if ($Content.ContainsKey($key)) {
                    $properties.Add($key, @($Content[$key]))
                }
            }
            return $properties
        }
        { $_ -in @("NRT", "Scheduled") } {
            $properties = [ordered]@{
                alertRuleTemplateName = $template ? $template : $Content["id"]
                description           = Get-CleanString -Value $Content.description
                displayName           = $Content["name"]
                enabled               = $enabled
                query                 = $Content["query"]
                severity              = $Content.ContainsKey("severity") ? $Content["severity"] : "Medium"
                suppressionDuration   = $Content.ContainsKey("suppressionDuration") ? (ConvertTo-ISO8601 -Value $Content["suppressionDuration"]) : "PT1H"
                suppressionEnabled    = $Content.ContainsKey("suppressionEnabled") ? $Content["suppressionEnabled"] : $false
                tactics               = $Content["tactics"]
                templateVersion       = $Content.ContainsKey("version") ? $Content["version"] : "1.0.0"
            }
            # Set optional fields
            $optionalFields = @(
                "alertDetailsOverride",
                "customDetails",
                "entityMappings",
                "eventGroupingSettings",
                "incidentConfiguration",
                "queryFrequency",
                "queryPeriod",
                "sentinelEntitiesMappings",
                "triggerOperator",
                "triggerThreshold"
            )
            foreach ($key in $optionalFields) {
                if ($Content.ContainsKey($key) -and $null -ne $Content[$key]) {
                    if (
                        (
                            $key -eq "entityMappings" -or
                            $key -eq "sentinelEntitiesMappings"
                        ) -and
                        $Content[$key] -isnot [array]
                    ) {
                        $properties.Add($key, @($Content[$key]))
                    } elseif (
                        $key -in @("queryFrequency", "queryPeriod")
                    ) {
                        $properties.Add($key, (ConvertTo-ISO8601 -Value $Content[$key]))
                    } elseif ($key -eq "triggerOperator") {
                        $properties.Add($key, (Convert-TriggerOperator -Value $Content[$key]))
                    } else {
                        $properties.Add($key, $Content[$key])
                    }
                    if (
                        $key -eq "incidentConfiguration" -and
                        $Content[$key].ContainsKey("groupingConfiguration") -and
                        $Content[$key]["groupingConfiguration"].ContainsKey("lookbackDuration") -and
                        $Content[$key]["groupingConfiguration"]["lookbackDuration"] -match '^\d+[dhmDHM]$'
                    ) {
                        $value = ConvertTo-ISO8601 -Value $Content[$key]["groupingConfiguration"]["lookbackDuration"]
                        $properties.$key.groupingConfiguration.lookbackDuration = $value
                    }
                }
            }
            # Set techniques and subTechniques
            $subTechniques = @()
            $techniques = @()
            foreach ($item in $Content["relevantTechniques"]) {
                if ($item -match " ") {
                    $item = $item -replace " ", ""
                }
                if ($item -eq "") {
                    continue
                }
                if ($item -match '\.') {
                    if (-not $subTechniques.Contains($item)) {
                        $subTechniques += $item
                    }
                    $item = ($item -split "\.")[0]
                }
                if (-not $techniques.Contains($item)) {
                    $techniques += ($item -split "\.")[0]
                }
            }
            if ($subTechniques.Count -gt 0) {
                $properties.Add("subTechniques", $subTechniques)
            }
            if ($techniques.Count -gt 0) {
                $properties.Add("techniques", $techniques)
            }
            return $properties
        }
        default {
            return [ordered]@{
                alertRuleTemplateName = $template ? $template : $Content["id"]
                enabled               = $enabled
            }
        }
    }
}
