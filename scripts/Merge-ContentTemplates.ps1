# Define the path to the module folder containing the .ps1 files
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\modules\MDR\Private"

# Retrieve all .ps1 files from the specified module folder
$scriptFiles = Get-ChildItem -Path $modulePath -Filter "*.ps1"

# Iterate through each .ps1 file and dot-source it to load its functions and variables into the current session
foreach ($scriptFile in $scriptFiles) {
    Write-Host "Loading script file: $($scriptFile.FullName)"
    . $scriptFile.FullName
}

Write-Host "All module scripts have been successfully loaded from: $modulePath"


<#
.SYNOPSIS
    Merges content files from various sources into ARM template(s).

.DESCRIPTION
    The Merge-ContentTemplate function reads content files from specified paths, applies any
    overrides, and merges them into ARM template(s). It supports smart deployment by checking
    if the content has changed since the last deployment, using a tracking table, and only
    deploying changed content. The function also handles files defined as a package.

.PARAMETER ConfigFile
    The name of the configuration file. This parameter is optional and defaults to "deployment-config.yaml".

.PARAMETER OutputPath
    The path where the merged ARM template(s) will be saved. This parameter is optional and
    defaults to "output".

.PARAMETER CurrentCustomerRootPath
    The path to the source / customer content repository files. This parameter is mandatory.

.EXAMPLE
    PS C:\> Merge-ContentTemplate -CurrentCustomer "Adrian"

    Merges content files without using smart deployment.
#>
function Merge-ContentTemplate {
    [CmdletBinding()]
    [OutputType([void])]
    param (
        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string]
        $ConfigFile = "deployment-config.yaml",

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string]
        $OutputPath = "output",

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string]
        $AllCustomersRootPath = (Join-Path -Path (Split-Path $PSScriptRoot -Parent) -ChildPath "customers"),

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        # TODO: should be overridden by the caller
        $CurrentCustomer


    )
    # Reduce the likelihood of runtime errors caused by common mistakes.
    Set-StrictMode -Version 3.0

    # Define initial variables
    # Prefix CurrentCustomerRootPath with repository root
    if (-not $CurrentCustomer) {
        throw "CurrentCustomer parameter is not provided or invalid."
    }
    $CurrentCustomerRootPath = (Join-Path -Path $AllCustomersRootPath -ChildPath $CurrentCustomer)
    $configFilePath = (Join-Path -Path $CurrentCustomerRootPath -ChildPath $ConfigFile)
    $outputExist = $false

    # Dynamically load the correct configuration file for each customer
    $configFilePath = Join-Path -Path $CurrentCustomerRootPath -ChildPath $ConfigFile
    if (-not (Test-Path -LiteralPath $configFilePath -PathType Leaf)) {
        throw "Config file not found for $CurrentCustomer to ${configFilePath}" 
    }

    Write-Host "Loading configuration for $CurrentCustomer from $configFilePath..."
    $config = Read-YamlFile -FilePath $configFilePath

    # Validate the loaded configuration
    if (-not $config) {
        throw "Failed to load configuration for $CurrentCustomer."
    }
    Write-Host "Configuration loaded successfully for $CurrentCustomer."

    # Check that config file exist
    if (-not (Test-Path -LiteralPath $configFilePath -PathType Leaf)) {
        # Set-WorkflowOutput -Variable "result" -Text 'failure'
        Write-Host "Config file not found: ${configFilePath}"
        throw "Unable to find ${ConfigFile}, aborting..."
    }

    # Read config file into variable config
    #Write-Message -Message "Get configuration from ${ConfigFile}..."
    Write-Host "Get configuration from ${ConfigFile}..."
    try {
        $config = Read-YamlFile -FilePath $configFilePath -File $ConfigFile -Ordered
        Write-Host "Config: $($config | ConvertTo-Json -Depth 99)"
    } catch {
        #Set-WorkflowOutput -Variable "result" -Text 'failure'
        Write-Host "Failed to read config file: ${configFilePath}"
        throw
    }

    # Check that config is not null
    if ([string]::IsNullOrWhiteSpace($config)) {
        Set-WorkflowOutput -Variable "result" -Text 'failure'
        throw "Missing config. Please fix ${ConfigFile}."
    } else {
        Write-Host "Config is valid."
    }

    # Check that config is an ordered dictionary
    if ($config -isnot [ordered]) {
        Set-WorkflowOutput -Variable "result" -Text 'failure'
        throw (
            "Expected config to be an ordered dictionary but it is $($config.GetType().FullName). " +
            "Please fix ${ConfigFile}."
        )
    }

    # Check that config has a settings property
    if (-not $config.Keys.Contains("Settings")) {
        Set-WorkflowOutput -Variable "result" -Text 'failure'
        throw (
            "Expected a settings property in config. Please fix ${ConfigFile}."
        )
    } elseif (-not $config.Keys.Contains("Connectors")) { 
        Set-WorkflowOutput -Variable "result" -Text 'failure'
        throw (
            "Expected a Connectors property in config. Please fix ${ConfigFile}."
        )
    } else {
        Write-Host "Config has Settings and Connectors property."
    }

    # Check that output path exist, create if not
    if (-not (Test-Path -LiteralPath $OutputPath -PathType Container)) {
        Write-Message -Message "Create output path ${OutputPath}..."
        New-Item -Path $OutputPath -ItemType Directory | Out-Null
    }

    # Check that config has a required settings
    $requiredSettings = 'CustomerName', 'Location', 'Workspace-Name', 'Automation-Resource-Group'
    foreach ($key in $requiredSettings) {
        if (-not $config["settings"].Keys.Contains($key) -or [string]::IsNullOrWhiteSpace($config["settings"][$key])) {
            Set-WorkflowOutput -Variable "result" -Text 'failure'
            throw (
                "Expected a '$key' property in settings. Please fix ${ConfigFile}."
            )
        }
    }

    # Define the template
    $workspace = $config["Settings"]["Workspace-Name"]
    $location = $config["Settings"]["Location"]
    Write-Host "Workspace: $workspace"
    Write-Host "Location: $location"
    $template = @{
        '$schema'      = "https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#"
        contentVersion = "1.0.0.0"
        parameters     = @{
            workspace            = @{
                type         = "string"
                defaultValue = $workspace
                metadata     = @{
                    description = "The name of the Log Analytics workspace where Microsoft Sentinel is set up."
                }
            }
            "workspace-location" = @{
                type         = "string"
                defaultValue = $location
                metadata     = @{
                    description = "The region to deploy Data Connectors and other workspace resources that require a location property."
                }
            }
        }
        resources      = @()
    }

    Write-Host "Template: $($template | ConvertTo-Json -Depth 99)"

    # hashtable to store filepaths
    $filePaths = @{}

    # Loop though all *.yaml files in "/Shared Artifacts"



    # Loop through all *.yaml files in "/Shared Artifacts"
    $sharedArtifactsPath = Join-Path -Path (Split-Path $PSScriptRoot -Parent) -ChildPath "../Shared Artifacts"
    $customerRulesPath = Join-Path -Path $CurrentCustomerRootPath -ChildPath "Rules"

    # Cache ExcludeRules from the config
    # ExcludeRules is a list of IDs to exclude from processing. TODO.
    $excludeRules = $config["ExcludeRules"]

    # Cache enabled connectors and datatypes
    $enabledConnectors = $config["Settings"]["Connectors"]

    # Initialize ARM template resources
    $resourceNames = @{}

    Write-Message -Message "$sharedArtifactsPath"

    # Process each YAML file in Shared Artifacts recursively
    Get-ChildItem -Path $sharedArtifactsPath -Recurse -Filter "*.yaml" | ForEach-Object {
        $sharedFile = $_.FullName
        $sharedContent = Read-YamlFile -FilePath $sharedFile

        # Extract the ID from the shared file
        $sharedId = $sharedContent["id"]
        if (-not $sharedId) {
            Write-Host "Skipping file without ID: $sharedFile"
            return
        }

        # Check if the ID is in ExcludeRules
        if ($excludeRules -contains $sharedId) {
            Write-Host "Skipping excluded rule: $sharedId"
            return
        }

        # Check if the connector or datatype is disabled
        if (-not ($enabledConnectors -contains $sharedContent["connector"])) {
                # Log which ruleID and connector being skipped
            Write-Message -Message "Skipping disabled connector or datatype for rule: $sharedId"
            Write-Message -Message "Connector: $($sharedContent["connector"])"
            Write-Message -Message "File: $sharedFile"
            Write-Message -Message "Customer: $CurrentCustomer"
            Write-Host "Skipping disabled connector or datatype for rule: $sharedId"
            return
        }

        # Check for customer-specific override
        $customerFile = Join-Path -Path $CurrentCustomerRootPath -ChildPath "Artifacts/$sharedId.yaml"
        if (Test-Path -LiteralPath $customerFile -PathType Leaf) {
            Write-Host "Using customer-specific file for ID: $sharedId"
            $content = Read-YamlFile -FilePath $customerFile
        } else {
            Write-Host "Using shared file for ID: $sharedId"
            $content = $sharedContent
        }

        # Convert the content to an ARM template resource
        $resource = ConvertTo-ContentResource -Content $content -Config $config
        if ($null -ne $resource -and $resource.Keys.Contains("name")) {
            $name = $resource["name"]

            # Skip duplicate resources
            if ($resourceNames.ContainsKey($name)) {
                Write-Host "Skipping duplicate resource: $name"
                return
            }
            $resourceNames[$name] = 1

            # Add the resource to the ARM template
            $template["resources"] += $resource
            Write-Host "Added resource: $name"
        } else {
            Write-Host "Invalid or missing resource for ID: $sharedId"
        }
    }

    # Process rules directly from deployment-config.yaml
    $rulesPath = Join-Path -Path $CurrentCustomerRootPath -ChildPath "Rules"

    # Loop through all rule files in the customer's Rules folder
    Get-ChildItem -Path $rulesPath -Recurse -Filter "*.yaml" | ForEach-Object {
        $ruleFile = $_.FullName
        $ruleContent = Read-YamlFile -FilePath $ruleFile

        # Extract the ID from the rule file
        $ruleId = $ruleContent["id"]
        if (-not $ruleId) {
            Write-Host "Skipping rule file without ID: $ruleFile"
            return
        }

        # Check if the ID is in ExcludeRules
        if ($excludeRules -contains $ruleId) {
            Write-Host "Skipping excluded rule: $ruleId"
            return
        }

        # Check if the connector is disabled
        $connector = $ruleContent["connector"]
        if ($null -ne $connector -and -not ($enabledConnectors | Where-Object { $_.id -eq $connector -and $_.enabled })) {
            Write-Host "Skipping disabled connector for rule: $ruleId"
            return
        }

        # Convert the rule content to an ARM template resource
        $resource = ConvertTo-ContentResource -Content $ruleContent -Config $config

        if ($null -ne $resource -and $resource.Keys.Contains("name")) {
            $name = $resource["name"]

            # Skip duplicate resources
            if ($resourceNames.ContainsKey($name)) {
                Write-Host "Skipping duplicate resource: $name"
                return
            }
            $resourceNames[$name] = 1

            # Add the resource to the ARM template
            $template["resources"] += $resource
            Write-Host "Added resource: $name"
        } else {
            Write-Host "Invalid or missing resource for rule: $ruleId"
        }
    }

    # Process additional rules in the customer's Artifacts folder
    $artifactsPath = Join-Path -Path $CurrentCustomerRootPath -ChildPath "Artifacts"
    Get-ChildItem -Path $artifactsPath -Recurse -Filter "*.yaml" | ForEach-Object {
        $artifactFile = $_.FullName
        $artifactContent = Read-YamlFile -FilePath $artifactFile

        # Extract the ID from the artifact file
        $artifactId = $artifactContent["id"]
        if (-not $artifactId) {
            Write-Host "Skipping artifact file without ID: $artifactFile"
            return
        }

        # Convert the artifact content to an ARM template resource
        $resource = ConvertTo-ContentResource -Content $artifactContent -Config $config
        if ($null -ne $resource -and $resource.Keys.Contains("name")) {
            $name = $resource["name"]

            # Skip duplicate resources
            if ($resourceNames.ContainsKey($name)) {
                Write-Host "Skipping duplicate resource: $name"
                return
            }
            $resourceNames[$name] = 1

            # Add the resource to the ARM template
            $template["resources"] += $resource
            Write-Host "Added resource: $name"
        } else {
            Write-Host "Invalid or missing resource for artifact: $artifactId"
        }
    }

    # Generate the ARM template for the current customer
    $templateJson = $template | ConvertTo-Json -Depth 99 -Compress
    Write-Output $templateJson

    # Ensure the output is valid
    if (-not $templateJson) {
        throw "Failed to generate ARM template for $CurrentCustomer. Output is empty."
    }

    Write-Host "ARM template successfully generated for $CurrentCustomer."
}

