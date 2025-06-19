function Remove-SentinelAnalyticsRules {
    param (
        [Parameter(Mandatory)]
        [string]$SubscriptionId,

        [Parameter(Mandatory)]
        [string]$ResourceGroupName,

        [Parameter(Mandatory)]
        [string]$WorkspaceName,

        [Parameter(Mandatory)]
        [string]$RuleIdFilePath # JSON (.json) or text (.txt) file
    )

    Write-Host "::INFO:: Authenticating to Azure..."
    Connect-AzAccount -Identity -ErrorAction Stop
    Set-AzContext -SubscriptionId $SubscriptionId

    if (!(Test-Path $RuleIdFilePath)) {
        Write-Error "::ERROR:: File not found: $RuleIdFilePath"
        return
    }

    Write-Host "::INFO:: Reading rule IDs from file..."
    $extension = [System.IO.Path]::GetExtension($RuleIdFilePath)
    $ruleIds = @()

    switch ($extension) {
        ".json" {
            try {
                $json = Get-Content $RuleIdFilePath -Raw | ConvertFrom-Json
                $ruleIds = $json
            } catch {
                Write-Error "::ERROR:: Failed to parse JSON file: $_"
                return
            }
        }
        ".txt" {
            $ruleIds = Get-Content $RuleIdFilePath | Where-Object { $_.Trim() -ne "" }
        }
        default {
            Write-Error "::ERROR:: Unsupported file format: $extension. Use .json or .txt"
            return
        }
    }

    foreach ($ruleId in $ruleIds) {
        $ruleIdTrimmed = $ruleId.Trim()
        $resourceId = "/subscriptions/$SubscriptionId/resourceGroups/$ResourceGroupName/providers/Microsoft.OperationalInsights/workspaces/$WorkspaceName/providers/Microsoft.SecurityInsights/alertRules/$ruleIdTrimmed"

        Write-Host "::INFO:: Checking existence of rule: $ruleIdTrimmed"
        try {
            $existingRule = Get-AzResource -ResourceId $resourceId -ErrorAction Stop
        } catch {
            Write-Warning "::WARN:: Rule not found: $ruleIdTrimmed. Skipping..."
            continue
        }

        Write-Host "::INFO:: Deleting rule: $ruleIdTrimmed"
        try {
            Remove-AzResource -ResourceId $resourceId -Force -Confirm:$false
            Write-Host "::SUCCESS:: Deleted rule $ruleIdTrimmed"
        } catch {
            Write-Warning "::WARN:: Failed to delete rule $ruleIdTrimmed - $_"
        }
    }
}