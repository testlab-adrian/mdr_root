<#
.SYNOPSIS
Initiates an ARM template deployment process based on a YAML configuration.

.DESCRIPTION
This function reads a YAML configuration file (specified by the ConfigFile parameter) and
validates its contents to ensure that required settings exist. It then searches for ARM JSON
templates in the provided TemplatePath and, if deployment is approved via ShouldProcess, it
executes an Azure CLI deployment for each template. If waitSecondsBeforeStart is defined in
the config, the deployment will wait for the specified number of seconds before starting.
The deployment reports are saved in the directory specified by the OutputPath.
If the Test switch is used, the deployment is started in "what-if" mode.

.PARAMETER ConfigFile
The path to the YAML configuration file that contains deployment settings.
The default value is "deployment-config.yaml".

.PARAMETER OutputPath
The folder where deployment report files will be saved. If the folder does not exist,
the function attempts to create it. The default value is "output".

.PARAMETER TemplatePath
The folder containing the ARM JSON template files that will be processed.
This parameter is mandatory.

.PARAMETER Test
If this switch is specified, the function will execute the deployment in "what-if" mode.

.EXAMPLE
Start-ContentDeploy -ConfigFile "deployment-config.yaml" -OutputPath "output" `
    -TemplatePath "templates"
This example reads the configuration from "deployment-config.yaml", locates ARM templates
in the "templates" directory, and stores the generated deployment reports in the "output"
directory.

.EXAMPLE
Start-ContentDeploy -ConfigFile "deployment-config.yaml" -OutputPath "output" `
    -TemplatePath "templates" -Test
This example reads the configuration from "deployment-config.yaml", locates ARM templates
in the "templates" directory, and stores the generated deployment what-if reports in the
"output" directory.

.NOTES
Ensure that the Azure CLI is installed and accessible. The function also depends on helper
functions such as Write-Message and Read-YamlFile being available in the session.
#>
function Start-ContentDeploy {
    [CmdletBinding(SupportsShouldProcess = $true)]
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

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $TemplatePath,

        [Parameter(Mandatory = $false)]
        [switch]
        $Test
    )
    Set-StrictMode -Version 3.0
    $configFileObject = Get-Item -Path $ConfigFile
    $configFileName = $configFileObject.Name
    $configFilePath = $configFileObject.FullName
    $templates = @()

    # Read config file into variable config
    Write-Message -Message "Get configuration from ${configFileName}..."
    $config = Read-YamlFile -FilePath $configFilePath -File $configFileName

    # Check that config is not null
    if ([string]::IsNullOrWhiteSpace($config)) {
        throw "Missing config. Please fix ${configFileName}."
    }

    # Check that config is a hashtable
    if ($config -isnot [hashtable]) {
        throw (
            "Expected config to be a hashtable but it is $($config.GetType().FullName). " +
            "Please fix ${configFileName}."
        )
    }

    # Check that config has a settings property
    if (-not $config.ContainsKey("settings")) {
        throw (
            "Expected a settings property in config. Please fix ${configFileName}."
        )
    }

    $settings = $config['settings']

    # Verify required setting exists and is not empty
    if (
        -not $settings.ContainsKey("workspace-resource-group") -or
        [string]::IsNullOrWhiteSpace($settings["workspace-resource-group"])
    ) {
        throw "Expected a 'workspace-resource-group' property in settings. Please fix ${configFileName}."
    }

    # Ensure the output directory exists
    if (-not (Test-Path -Path $OutputPath -PathType Container)) {
        try {
            New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
        } catch {
            throw "Failed to create output directory: $_"
        }
    }

    # Find all ARM .json files in the TemplatePath (including subdirectories)
    try {
        $templates = @(Get-ChildItem -Path $TemplatePath -Filter *.json -Recurse)
    } catch {
        throw "Failed to retrieve ARM template files: $_"
    }

    if (-not $templates.Count -gt 0) {
        Write-Message -Message "No ARM templates found in ${TemplatePath}."
        return
    }

    # Loop through each ARM template file
    foreach ($template in $templates) {
        # If waitSecondsBeforeStart is defined in the config
        $deploymentName = $template.BaseName -replace '-\d+$', ''
        if (
            -not $Test -and
            $config.ContainsKey('deployments') -and
            $config['deployments'].ContainsKey($deploymentName) -and
            $config['deployments'][$deploymentName].ContainsKey('waitSecondsBeforeStart') -and
            $config['deployments'][$deploymentName]['waitSecondsBeforeStart'] -match '\d+'
        ) {
            # Wait for a specified number of seconds before starting the deployment
            Start-Sleep -Seconds $config['deployments'][$deploymentName]['waitSecondsBeforeStart']
        }
        if ($Test) {
            Write-Message -Message "Testing template: $($template.Name)"
        } else {
            Write-Message -Message "Deploy: $($template.Name)"
        }
        if ($PSCmdlet.ShouldProcess($template.Name, "deploy")) {
            try {
                # Define report file path based on the ARM template filename
                $reportFileName = "$($template.BaseName)_create.txt"
                $reportFilePath = Join-Path -Path $OutputPath -ChildPath $reportFileName
                $encoding = [System.Text.Encoding]::UTF8

                # Execute a deployment with the -WhatIf parameter
                $(
                    if ($Test) {
                        az deployment group what-if `
                            --template-file $template.FullName `
                            --resource-group $settings['workspace-resource-group'] `
                            --exclude-change-types Ignore NoChange Unsupported `
                            --no-prompt true *>&1
                    } else {
                        az deployment group create `
                            --template-file $template.FullName `
                            --resource-group $settings['workspace-resource-group'] `
                            --no-prompt true *>&1
                    }
                ) | Tee-Object -LiteralPath $reportFilePath -Encoding $encoding

                Write-Message -Message "Report saved to: $reportFilePath"
            } catch {
                throw "Failed processing template '$($template.Name)': $_"
            }
        }
    }
}
