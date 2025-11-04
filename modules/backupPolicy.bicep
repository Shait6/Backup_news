@description('Parent Recovery Services Vault resource name')
param vaultName string
@description('Name of the backup policy')
param backupPolicyName string
@description('Backup frequency: Daily or Weekly')
@allowed([
  'Daily'
  'Weekly'
])
param backupFrequency string = 'Daily'
@description('Backup run times (UTC)')
param backupScheduleRunTimes array
@description('Weekly run days (used when backupFrequency == "Weekly")')
param weeklyBackupDaysOfWeek array = []
@description('Retention in days')
param backupRetentionDays int = 30

// Reference existing vault as parent
resource existingVault 'Microsoft.RecoveryServices/vaults@2025-02-01' existing = {
  name: vaultName
}

resource backupPolicy 'Microsoft.RecoveryServices/vaults/backupPolicies@2023-04-01' = {
  parent: existingVault
  name: backupPolicyName
  properties: {
    backupManagementType: 'AzureIaasVM'
    schedulePolicy: {
      schedulePolicyType: 'SimpleSchedulePolicy'
      scheduleRunFrequency: backupFrequency
      scheduleRunTimes: backupScheduleRunTimes
      scheduleRunDays: backupFrequency == 'Weekly' ? weeklyBackupDaysOfWeek : null
    }
    retentionPolicy: {
      retentionPolicyType: 'LongTermRetentionPolicy'
      dailySchedule: {
        retentionTimes: backupScheduleRunTimes
        retentionDuration: {
          count: backupRetentionDays
          durationType: 'Days'
        }
      }
    }
    timeZone: 'UTC'
  }
}

output backupPolicyId string = backupPolicy.id
output backupPolicyName string = backupPolicy.name