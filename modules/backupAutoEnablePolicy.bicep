targetScope = 'subscription'

@description('Name for the custom DeployIfNotExists policy definition')
param policyName string = 'deployifnotexists-enable-vm-backup'
@description('Name for the policy assignment')
param policyAssignmentName string = 'enable-vm-backup-assignment'

@description('VM tag name to filter which VMs the policy applies to (e.g. "backup")')
param vmTagName string = 'backup'
@description('VM tag value to match (e.g. "true")')
param vmTagValue string = 'true'

@description('Recovery Services Vault name to use when enabling backup')
param vaultName string
@description('Resource group of the Recovery Services Vault')
param vaultResourceGroup string
@description('Backup policy name to apply when enabling backup')
param backupPolicyName string

// Role required to perform remediation (Contributor covers backup operations)
var roleDefinitionIds = [subscriptionResourceId('Microsoft.Authorization/roleDefinitions','b24988ac-6180-42a0-ab88-20f7382dd24c')]

// Policy definition: DeployIfNotExists to enable backup for tagged VMs
var policyRuleJson = '{"if":{"allOf":[{"field":"type","equals":"Microsoft.Compute/virtualMachines"},{"field":"tags[\'${vmTagName}\']","equals":"${vmTagValue}"},{"not":{"exists":{"field":"Microsoft.RecoveryServices/vaults/backupFabrics/protectionContainers/protectedItems/name"}}}]},"then":{"effect":"deployIfNotExists","details":{"type":"Microsoft.Resources/deployments","roleDefinitionIds":["${roleDefinitionIds[0]}"],"deployment":{"properties":{"mode":"Incremental","parameters":{"vmId":{"value":"[field(\'fullName\')]"},"vaultName":{"value":"${vaultName}"},"vaultResourceGroup":{"value":"${vaultResourceGroup}"},"backupPolicyName":{"value":"${backupPolicyName}"}},"template":{"$schema":"https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#","contentVersion":"1.0.0.0","parameters":{"vmId":{"type":"string"},"vaultName":{"type":"string"},"vaultResourceGroup":{"type":"string"},"backupPolicyName":{"type":"string"}},"resources":[{"type":"Microsoft.RecoveryServices/vaults/backupFabrics/protectionContainers/protectedItems","apiVersion":"2023-04-01","name":"[concat(parameters(\'vaultName\'), \'/Azure/protectionContainers/protectedItems-\', replace(replace(parameters(\'vmId\'), \'/\', \'-\'), \':\', \'-\'))]","properties":{"protectedItemType":"Microsoft.Compute/virtualMachines","sourceResourceId":"[parameters(\'vmId\')]","policyId":"[subscriptionResourceId(\'Microsoft.RecoveryServices/vaults/backupPolicies\', parameters(\'vaultName\'), parameters(\'backupPolicyName\'))]"}}]}}}}}'

resource policyDef 'Microsoft.Authorization/policyDefinitions@2021-06-01' = {
  name: policyName
  properties: {
    displayName: 'DeployIfNotExists: enable VM backup for tagged VMs'
    policyType: 'Custom'
    mode: 'Indexed'
    description: 'If a virtual machine with the specified tag does not have a Recovery Services protected item, deploy an ARM template to enable backup using the specified vault and policy.'
    metadata: {
      category: 'Backup'
      version: '1.0'
      createdBy: 'VM_Backup_Solution'
    }
    policyRule: json(policyRuleJson)
  }
}

resource policyAssign 'Microsoft.Authorization/policyAssignments@2021-06-01' = {
  name: policyAssignmentName
  properties: {
    displayName: 'Enable VM backup for tagged VMs'
    description: 'Assign DeployIfNotExists policy to enable VM backup for VMs with the tag.'
    policyDefinitionId: policyDef.id
    parameters: {}
  }
}

output policyDefinitionId string = policyDef.id
output policyAssignmentId string = policyAssign.id
