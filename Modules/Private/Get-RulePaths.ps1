param(
    [string]$customerName,
    [string]$sharedArtifactsPath,
    [string]$customerArtifactsPath
)

$VerbosePreference = 'Continue'
function Get-CustomerRules {    
    [CmdletBinding()]
    param (
        [string]$customerName,
        [string]$sharedArtifactsPath,
        [string]$customerArtifactsPath
    )
    
    if (Get-Module -ListAvailable -Name powershell-yaml) {
        Write-Verbose "Module already installed"
    } else {
        Write-Verbose "Installing PowerShell-YAML module"
        try {
            Install-Module powershell-yaml -AllowClobber -Force -ErrorAction Stop
            Import-Module powershell-yaml
        } catch {
            Write-Error $_.Exception.Message
            break
        }
    }

    # initialize variables
    $sharedRules = @()
    $customerSpecificRules = @()
    $customerExclusions = @()
    $customerConnectors = @()

    Write-Verbose "Shared artifacts path: $sharedArtifactsPath"
    Write-Verbose "Customer artifacts path: $customerArtifactsPath"

    # Process shared artifact files
    $sharedArtifacts = Get-ChildItem -Path $sharedArtifactsPath -Include *.yaml, *.yml -Recurse -File
    Write-Verbose "Found $($sharedArtifacts.Count) shared artifact file(s)."
    foreach ($file in $sharedArtifacts) {
        Write-Verbose "Processing shared file: $($file.FullName)"
        $yamlContent = Get-Content -Path $file.FullName -Raw
        $parsedYaml = ConvertFrom-Yaml -Yaml $yamlContent
        if ($parsedYaml -is [hashtable]) {
            if ($parsedYaml.ContainsKey("id")) {
                Write-Verbose "   Found rule with id: $($parsedYaml.id)"
                $parsedYaml | Add-Member -MemberType NoteProperty -Name path -Value $file.FullName -Force
                $sharedRules += $parsedYaml
            } elseif ($parsedYaml.ContainsKey("rules")) {
                foreach ($r in $parsedYaml.rules) {
                    Write-Verbose "   Found rule with id: $($r.id)"
                    $r | Add-Member -MemberType NoteProperty -Name path -Value $file.FullName -Force
                    $sharedRules += $r
                }
            }
        }
    }

    # Process customer artifact files
    $customerArtifacts = Get-ChildItem -Path $customerArtifactsPath -Include *.yaml, *.yml -Recurse -File
    Write-Verbose "Found $($customerArtifacts.Count) customer artifact file(s)."
    foreach ($file in $customerArtifacts) {
        Write-Verbose "Processing customer file: $($file.FullName)"
        $yamlContent = Get-Content -Path $file.FullName -Raw
        $parsedYaml = ConvertFrom-Yaml -Yaml $yamlContent
        if ($parsedYaml -is [hashtable]) {
            if ($parsedYaml.ContainsKey("id")) {
                Write-Verbose "   Found rule with id: $($parsedYaml.id)"
                $parsedYaml | Add-Member -MemberType NoteProperty -Name path -Value $file.FullName -Force
                $customerSpecificRules += $parsedYaml
            } elseif ($parsedYaml.ContainsKey("rules")) {
                foreach ($r in $parsedYaml.rules) {
                    Write-Verbose "   Found rule with id: $($r.id)"
                    $r | Add-Member -MemberType NoteProperty -Name path -Value $file.FullName -Force
                    $customerSpecificRules += $r
                }
            }
        }
    }

    # Resolve absolute path for deployment-config.yaml to get customer connectors and exclusions
    $deploymentConfigPath = [System.IO.Path]::GetFullPath((Join-Path $customerArtifactsPath "deployment-config.yaml"))
    Write-Verbose "Deployment config path: $deploymentConfigPath"
    $depConfigContent = Get-Content -Path $deploymentConfigPath -Raw
    $deploymentConfig = ConvertFrom-Yaml -Yaml $depConfigContent

    # Determine enabled connectors & exclusion ids
    $enabledConnectorIds = $deploymentConfig.Connectors | Where-Object { $_.enabled -eq $true } | ForEach-Object { $_.id }
    $exclusionIds = $deploymentConfig.ExcludeRules | ForEach-Object { $_.id }
    Write-Verbose "Enabled Connectors: $($enabledConnectorIds -join ', ')"
    Write-Verbose "Exclusion IDs: $($exclusionIds -join ', ')"

    # Build final rules list
    $finalRules = @()
    $customerSpecificIds = $customerSpecificRules | ForEach-Object { $_.id }

    # Process customer-specific rules with override and exclusion check
    foreach ($rule in $customerSpecificRules) {
        Write-Host "Evaluating customer rule: $($rule.id)" -ForegroundColor Yellow
        if ($exclusionIds -contains $rule.id) {
            Write-Host "   Skipping rule $($rule.id) as it is excluded." -ForegroundColor Red
            continue
        }
        $rule | Add-Member -MemberType NoteProperty -Name requiredDataConnectors -Value @() -Force
        Write-Host "   Adding customer rule: $($rule.id)" -ForegroundColor Green
        $finalRules += $rule
    }

    # Process shared rules not overridden by customer-specific ones
    foreach ($rule in $sharedRules) {
        Write-Host "Evaluating shared rule: $($rule.id)" -ForegroundColor Yellow
        if ($customerSpecificIds -contains $rule.id) {
            Write-Host "   Skipping shared rule $($rule.id) as overridden by customer rule." -ForegroundColor Red
            continue
        }
        if ($exclusionIds -contains $rule.id) {
            Write-Host "   Skipping shared rule $($rule.id) as it is excluded." -ForegroundColor Red
            continue
        }
        $rule | Add-Member -MemberType NoteProperty -Name requiredDataConnectors -Value @() -Force
        Write-Host "   Adding shared rule: $($rule.id)" -ForegroundColor Green
        $finalRules += $rule
    }

    Write-Verbose "Total rules to be returned: $($finalRules.Count)"

    # Extract only the file paths of the rules to deploy and output as JSON.
    $finalRulePaths = $finalRules | ForEach-Object { $_.path }  
    #Write-Verbose "Final rule paths: $($finalRulePaths -join ', ')"
    Write-Host ($finalRulePaths | ConvertTo-Json)
    return $finalRulePaths

}
