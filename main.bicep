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
  'Both'
])
@description('Backup frequency - choose Daily, Weekly or Both')
param backupFrequency string = 'Daily'

@allowed([
  'Enabled'
  'Disabled'
])
param publicNetworkAccess string = 'Enabled'
@description('Recovery Services Vault SKU name (e.g. RS0)')
param vaultSkuName string = 'RS0'
@description('Recovery Services Vault SKU tier (e.g. Standard)')
param vaultSkuTier string = 'Standard'
// Recommended replication: GRS — set the vault replication manually after creation if needed.

// Deploy Recovery Services Vault using a module
module vaultModule './modules/recoveryVault.bicep' = {
  name: 'recoveryVaultModule'
  params: {
    vaultName: vaultName
    location: location
    publicNetworkAccess: publicNetworkAccess
    skuName: vaultSkuName
    skuTier: vaultSkuTier
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
output backupPolicyIds array = policyModule.outputs.backupPolicyIds
output backupPolicyNames array = policyModule.outputs.backupPolicyNames
