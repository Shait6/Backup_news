@description('Location for all resources')
param location string
param vaultName string
param backupPolicyName string
param backupScheduleRunTimes array = [
  '2023-12-31T01:00:00Z'
]
param backupRetentionDays int = 30
param weeklyBackupDaysOfWeek array = [
  'Sunday'
  'Wednesday'
]

@allowed([
  'Daily'
  'Weekly'
])
@description('Backup frequency - choose Daily or Weekly')
param backupFrequency string = 'Daily'

@allowed([
  'Enabled'
  'Disabled'
])
param publicNetworkAccess string = 'Enabled'

resource recoveryServicesVault 'Microsoft.RecoveryServices/vaults@2023-04-01' = {
  name: vaultName
  location: location
  sku: {
    name: 'RS0'
    tier: 'Standard'
  }
  properties: {
    publicNetworkAccess: publicNetworkAccess
    restoreSettings: {
      crossSubscriptionRestoreSettings: {
        crossSubscriptionRestoreState: 'Enabled'
      }
    }
  }
}

resource backupPolicy 'Microsoft.RecoveryServices/vaults/backupPolicies@2023-04-01' = {
  parent: recoveryServicesVault
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

// Output the vault ID and backup policy ID for use in the Azure Policy
output vaultId string = recoveryServicesVault.id
output policyId string = backupPolicy.id