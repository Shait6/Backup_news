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

// Deploy Recovery Services Vault using a module
module vaultModule './modules/recoveryVault.bicep' = {
  name: 'recoveryVaultModule'
  params: {
    vaultName: vaultName
    location: location
    publicNetworkAccess: publicNetworkAccess
  }
}

// Deploy Backup Policy using a module; depends on vault
module policyModule './modules/backupPolicy.bicep' = {
  name: 'backupPolicyModule'
  params: {
    vaultName: vaultName
    backupPolicyName: backupPolicyName
    backupFrequency: backupFrequency
    backupScheduleRunTimes: backupScheduleRunTimes
    weeklyBackupDaysOfWeek: weeklyBackupDaysOfWeek
    backupRetentionDays: backupRetentionDays
  }
  dependsOn: [vaultModule]
}

// Export module outputs
output vaultId string = vaultModule.outputs.vaultId
output policyId string = policyModule.outputs.backupPolicyId
