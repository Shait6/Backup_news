@description('Parent Recovery Services Vault resource name')
param vaultName string
@description('Name of the backup policy')
param backupPolicyName string
@description('Backup frequency: Daily, Weekly, or Both')
@allowed([
  'Daily'
  'Weekly'
  'Both'
])
param backupFrequency string = 'Daily'
@description('Backup run times (UTC)')
param backupScheduleRunTimes array
@description('Weekly run days (used when backupFrequency == "Weekly")')
param weeklyBackupDaysOfWeek array = []
@description('Retention in days for daily backups')
param dailyRetentionDays int = 14
@description('Retention in days for weekly backups')
param weeklyRetentionDays int = 30

// Reference existing vault as parent
resource existingVault 'Microsoft.RecoveryServices/vaults@2025-02-01' existing = {
  name: vaultName
}

// Create daily policy when requested (or when 'Both' selected)
resource backupPolicyDaily 'Microsoft.RecoveryServices/vaults/backupPolicies@2023-04-01' = if (backupFrequency == 'Daily' || backupFrequency == 'Both') {
  parent: existingVault
  name: backupFrequency == 'Both' ? '${backupPolicyName}-daily' : backupPolicyName
  properties: {
    backupManagementType: 'AzureIaasVM'
    schedulePolicy: {
      schedulePolicyType: 'SimpleSchedulePolicy'
      scheduleRunFrequency: 'Daily'
      scheduleRunTimes: backupScheduleRunTimes
      scheduleRunDays: null
    }
    retentionPolicy: {
      retentionPolicyType: 'LongTermRetentionPolicy'
      dailySchedule: {
        retentionTimes: backupScheduleRunTimes
        retentionDuration: {
          count: dailyRetentionDays
          durationType: 'Days'
        }
      }
    }
    timeZone: 'UTC'
  }
}

// Create weekly policy when requested (or when 'Both' selected)
resource backupPolicyWeekly 'Microsoft.RecoveryServices/vaults/backupPolicies@2023-04-01' = if (backupFrequency == 'Weekly' || backupFrequency == 'Both') {
  parent: existingVault
  name: backupFrequency == 'Both' ? '${backupPolicyName}-weekly' : backupPolicyName
  properties: {
    backupManagementType: 'AzureIaasVM'
    schedulePolicy: {
      schedulePolicyType: 'SimpleSchedulePolicy'
      scheduleRunFrequency: 'Weekly'
      scheduleRunTimes: backupScheduleRunTimes
      scheduleRunDays: weeklyBackupDaysOfWeek
    }
    retentionPolicy: {
      retentionPolicyType: 'LongTermRetentionPolicy'
      dailySchedule: {
        retentionTimes: backupScheduleRunTimes
        retentionDuration: {
          count: weeklyRetentionDays
          durationType: 'Days'
        }
      }
    }
    timeZone: 'UTC'
  }
}

output backupPolicyIds array = backupFrequency == 'Both' ? [backupPolicyDaily.id, backupPolicyWeekly.id] : (backupFrequency == 'Daily' ? [backupPolicyDaily.id] : (backupFrequency == 'Weekly' ? [backupPolicyWeekly.id] : []))

output backupPolicyNames array = backupFrequency == 'Both' ? [backupPolicyDaily.name, backupPolicyWeekly.name] : (backupFrequency == 'Daily' ? [backupPolicyDaily.name] : (backupFrequency == 'Weekly' ? [backupPolicyWeekly.name] : []))
