param([string]$Customer, [string]$OutputPath)

# Ensure PowerShell-Yaml module is installed
if (-not (Get-Module -ListAvailable -Name PowerShell-Yaml)) {
    Install-Module -Name PowerShell-Yaml -Force -Scope CurrentUser
}
Import-Module PowerShell-Yaml

# Define paths
$customerPath = "./customers/$Customer"
$rulesPath = "$customerPath/Rules"

# Initialize Bicep content
$bicepContent = "param customerName string\n\n"

# Function to convert YAML to Bicep
function Convert-YamlToBicep {
    param ([string]$YamlFile, [string]$BicepFile)

    try {
        $yamlContent = Get-Content -Path $YamlFile | ConvertFrom-Yaml
        # Example conversion logic (adjust based on actual YAML structure)
        $bicepContent = "// Converted from $YamlFile\nparam ruleName string = '${yamlContent.name}'\nparam ruleDescription string = '${yamlContent.description}'\n"
        Set-Content -Path $BicepFile -Value $bicepContent
    } catch {
        Write-Host "Failed to convert $YamlFile to Bicep: $_"
    }
}

# Add Scheduled Rules
$scheduledRules = Get-ChildItem -Path "$rulesPath/Scheduled" -Filter "*.yaml" -ErrorAction SilentlyContinue
foreach ($rule in $scheduledRules) {
    $bicepFile = "$rulesPath/Scheduled/${rule.BaseName}.bicep"
    Convert-YamlToBicep -YamlFile $rule.FullName -BicepFile $bicepFile
    $bicepContent += "module ${rule.BaseName} './customers/$Customer/Rules/Scheduled/${rule.BaseName}.bicep' = {\n"
    $bicepContent += "  name: '${Customer}-${rule.BaseName}'\n"
    $bicepContent += "}\n\n"
}

# Add NRT Rules
$nrtRules = Get-ChildItem -Path "$rulesPath/NRT" -Filter "*.yaml" -ErrorAction SilentlyContinue
foreach ($rule in $nrtRules) {
    $bicepFile = "$rulesPath/NRT/${rule.BaseName}.bicep"
    Convert-YamlToBicep -YamlFile $rule.FullName -BicepFile $bicepFile
    $bicepContent += "module ${rule.BaseName} './customers/$Customer/Rules/NRT/${rule.BaseName}.bicep' = {\n"
    $bicepContent += "  name: '${Customer}-${rule.BaseName}'\n"
    $bicepContent += "}\n\n"
}

# Add Hunting Rules
$huntingRules = Get-ChildItem -Path "$rulesPath/Hunting" -Filter "*.yaml" -ErrorAction SilentlyContinue
foreach ($rule in $huntingRules) {
    $bicepFile = "$rulesPath/Hunting/${rule.BaseName}.bicep"
    Convert-YamlToBicep -YamlFile $rule.FullName -BicepFile $bicepFile
    $bicepContent += "module ${rule.BaseName} './customers/$Customer/Rules/Hunting/${rule.BaseName}.bicep' = {\n"
    $bicepContent += "  name: '${Customer}-${rule.BaseName}'\n"
    $bicepContent += "}\n\n"
}

# Write to output file
Set-Content -Path $OutputPath -Value $bicepContent