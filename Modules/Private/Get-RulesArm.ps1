function Get-RulesArm {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$CustomerName
    )

    $VerbosePreference = "SilentlyContinue"
    Import-Module powershell-yaml

    $alertRules = @()
    # --- changed code: compute repository root and build a cross-platform path
    $repoRoot = (Resolve-Path "$PSScriptRoot/../../..").Path
    $alertRulesPath = "$repoRoot/customers/$CustomerName/artifacts/rules/scheduled"

    if (-not (Test-Path $alertRulesPath)) {
        Write-Warning "Path $alertRulesPath does not exist."
    }
    else {
        Get-ChildItem -Path $alertRulesPath -Recurse -Filter "*.yaml" | ForEach-Object {
            $yamlContent = Get-Content $_.FullName -Raw
            $rule = ConvertFrom-Yaml $yamlContent
            $alertRules += $rule
        }
    }

    # Save to a customer-specific parameter file
    $paramFile = @{
        "$schema" = "https://schema.management.azure.com/schemas/2019-04-01/deploymentParameters.json#"
        "contentVersion" = "1.0.0.0"
        "parameters" = @{
            "alertRules" = @{
                "value" = $alertRules
            }
        }
    }
    $paramOutput = "customers/$CustomerName/params.alertRules.json"
    $paramFile | ConvertTo-Json -Depth 10 | Out-File -FilePath $paramOutput -Encoding utf8
    Write-Output $paramOutput  # outputs the path or any other confirmation
}
