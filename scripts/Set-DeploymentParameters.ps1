# Main parameters script for VM Backup deployment
param(
    [Parameter(Mandatory=$true)]
    [string]$Location,

    [Parameter(Mandatory=$false)]
    [string]$SubscriptionId,

    [Parameter(Mandatory=$false)]
    [string]$VaultName = "rsv-backup-${env:resourceSuffix}",

    [Parameter(Mandatory=$false)]
    [string]$BackupPolicyName = "DefaultPolicy",

    [Parameter(Mandatory=$false)]
    [int]$BackupRetentionDays = 30,

    [Parameter(Mandatory=$false)]
    [array]$WeeklyBackupDaysOfWeek = @("Sunday", "Wednesday"),

    [Parameter(Mandatory=$false)]
    [array]$BackupScheduleRunTimes = @("2023-12-31T01:00:00Z"),
    
    [Parameter(Mandatory=$false)]
    [string]$VaultSkuName = 'RS0',

    [Parameter(Mandatory=$false)]
    [string]$VaultSkuTier = 'Standard'
)

# Create parameter hashtable
$parameters = @{
    location = $Location
    vaultName = $VaultName
    backupPolicyName = $BackupPolicyName
    backupRetentionDays = $BackupRetentionDays
    weeklyBackupDaysOfWeek = $WeeklyBackupDaysOfWeek
    backupScheduleRunTimes = $BackupScheduleRunTimes
    vaultSkuName = $VaultSkuName
    vaultSkuTier = $VaultSkuTier
    
}

# Convert to JSON
$parametersJson = @{
    '$schema' = "https://schema.management.azure.com/schemas/2019-04-01/deploymentParameters.json#"
    contentVersion = "1.0.0.0"
    parameters = @{}
}

foreach ($key in $parameters.Keys) {
    $parametersJson.parameters[$key] = @{
        value = $parameters[$key]
    }
}

# Output the JSON
$parametersJson | ConvertTo-Json -Depth 10 | Out-File "main.parameters.json"