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
    [int]$DailyRetentionDays = 14,

    [Parameter(Mandatory=$false)]
    [int]$WeeklyRetentionDays = 30,

    [Parameter(Mandatory=$false)]
    [array]$WeeklyBackupDaysOfWeek = @("Sunday", "Wednesday"),

    [Parameter(Mandatory=$false)]
    [array]$BackupScheduleRunTimes = @("01:00"),
    
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
    weeklyBackupDaysOfWeek = $WeeklyBackupDaysOfWeek
        # Use time-of-day strings (HH:mm) rather than full ISO datetimes to match Recovery Services API expectations
        backupScheduleRunTimes = $BackupScheduleRunTimes
    vaultSkuName = $VaultSkuName
    vaultSkuTier = $VaultSkuTier
}

# Set retention days based on backup frequency
$backupFrequency = $env:BACKUP_FREQUENCY
if ($backupFrequency -eq 'Daily') {
    # keep backward-compatible key
    $parameters["backupRetentionDays"] = $DailyRetentionDays
    # ensure explicit keys exist for templates expecting daily/weekly
    $parameters["dailyRetentionDays"] = $DailyRetentionDays
    $parameters["weeklyRetentionDays"] = $WeeklyRetentionDays
} elseif ($backupFrequency -eq 'Weekly') {
    $parameters["backupRetentionDays"] = $WeeklyRetentionDays
    $parameters["dailyRetentionDays"] = $DailyRetentionDays
    $parameters["weeklyRetentionDays"] = $WeeklyRetentionDays
} elseif ($backupFrequency -eq 'Both') {
    $parameters["dailyRetentionDays"] = $DailyRetentionDays
    $parameters["weeklyRetentionDays"] = $WeeklyRetentionDays
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