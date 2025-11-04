# Azure VM Backup Automation

This solution provides an automated way to deploy and configure VM backup infrastructure across multiple subscriptions in an Azure tenant using Azure Recovery Services Vault and Azure DevOps pipelines. It supports both automated and manual VM backup enablement for flexibility.

## Features

- Automated deployment of Recovery Services Vault and backup policies
- Support for both daily and weekly backup schedules
- Flexible retention periods with default 30-day retention
- Modular Bicep templates for maintainability
- Multi-region support (West Europe, North Europe, Sweden Central, Germany West Central)
- Optional public network access control
- Cross-subscription restore capability
- PowerShell scripts for automated VM backup enablement
- Manual backup option through Azure Portal

## Prerequisites

### Azure Subscription Requirements
1. Active Azure subscription
2. Owner or Contributor role on the subscription
3. Permissions to create and manage:
   - Resource Groups
   - Recovery Services Vaults
   - Backup Policies
   - VM Backup configurations

### Azure DevOps Requirements
1. Azure DevOps project
2. Service Principal with required permissions:
   - Contributor role on target subscription
   - Permissions to create resource groups
   - Permissions to manage Recovery Services vaults
3. Azure Service Connection configured in Azure DevOps project

### Optional Requirements for VM Backup
1. Existing Azure VMs or plans to deploy VMs
2. VM contributor permissions for enabling backup
3. Network connectivity between VMs and Recovery Services Vault

## Solution Architecture

### Components
1. **Recovery Services Vault**: Central backup management service
2. **Backup Policy**: Defines schedule and retention settings
3. **PowerShell Scripts**: For deployment and configuration
4. **Azure Pipeline**: Orchestrates the deployment
5. **Bicep Modules**: Infrastructure as Code templates

### Deployment Flow
1. Parameter preparation and validation
2. Resource Group creation (if not exists)
3. Recovery Services Vault deployment
4. Backup Policy configuration
5. Optional VM backup enablement

## Deployment Guide

### 1. Initial Setup
1. Clone this repository to your Azure DevOps project
2. Create an Azure Service Connection:
   - Navigate to Project Settings > Service Connections
   - Create new "Azure Resource Manager" connection
   - Name it 'Azure-ServiceConnection'
   - Grant access to pipelines

### 2. Pipeline Configuration
The pipeline is configured to run in stages with proper dependencies:
1. **PrepareParameters**: Validates and prepares deployment parameters
2. **CreateResourceGroup**: Creates resource group (depends on PrepareParameters)
3. **DeployBackupInfrastructure**: Deploys vault and policy (depends on CreateResourceGroup)

### 3. Pipeline Parameters
- `subscriptionId`: Target subscription ID
- `location`: Target region
  - westeurope
  - northeurope
  - swedencentral
  - germanywestcentral
- `resourceGroupName`: Name for the resource group
- `vaultName`: Name for the Recovery Services Vault
- `backupPolicyName`: Name for the backup policy
- `enableBackup`: Enable/disable backup deployment
- `backupFrequency`: Daily or Weekly backup schedule

### 4. Backup Configuration Options
- **Frequency Options**:
  - Daily: Runs once per day at specified time
  - Weekly: Runs on specified days (default: Sunday and Wednesday)
- **Default Settings**:
  - Retention period: 30 days (customizable)
  - Time zone: UTC
  - Public network access: Enabled (can be disabled)
  - Cross-subscription restore: Enabled

## Post-Deployment Steps

### Option 1: Manual VM Backup Configuration
1. Navigate to deployed Recovery Services Vault in Azure Portal
2. Click "Backup" in left menu
3. Choose "Azure Virtual Machine"
4. Select VMs to protect
5. Choose deployed backup policy
6. Click "Enable Backup"

### Option 2: Automated VM Backup Configuration
Use the provided PowerShell script:
```powershell
.\scripts\Enable-VMBackup.ps1 `
    -VaultName "your-vault-name" `
    -VaultResourceGroup "your-rg-name" `
    -VMName "your-vm-name" `
    -VMResourceGroup "vm-rg-name" `
    -BackupPolicyName "your-policy-name"
```

## Security Features
- Configurable public network access
- Cross-subscription restore enabled by default
- Standard tier storage redundancy
- Role-based access control (RBAC) support

## Troubleshooting

### Common Issues
1. **Pipeline Failures**:
   - Verify Azure Service Connection permissions
   - Check resource name availability
   - Ensure subscription has required resource providers

2. **Backup Policy Issues**:
   - Verify time zone settings
   - Check retention period limits
   - Validate schedule run times

3. **VM Backup Enablement**:
   - Ensure VM agent is installed and running
   - Check network connectivity to vault
   - Verify permissions on VM and vault

## Enabling VM Backup

After deploying the Recovery Services Vault and backup policy, you can enable backup for your VMs using either of these approaches:

### Option 1: Manual Enablement (Azure Portal)

1. Navigate to the Recovery Services Vault in Azure Portal
2. Click on "Backup" in the left menu
3. Select "Azure Virtual Machine" as workload type
4. Click "Backup"
5. Select the VMs you want to protect
6. Choose the backup policy created by this solution
7. Click "Enable Backup"

### Option 2: Automated Enablement (PowerShell)

You can use the following PowerShell commands to enable backup for VMs:

```powershell
# Connect to Azure (if not already connected)
Connect-AzAccount

# Set variables
$vaultName = "YourVaultName"
$resourceGroup = "YourResourceGroup"
$vmName = "YourVMName"
$vmResourceGroup = "YourVMResourceGroup"
$policyName = "YourBackupPolicyName"

# Get the vault and policy
$vault = Get-AzRecoveryServicesVault -Name $vaultName -ResourceGroupName $resourceGroup
$policy = Get-AzRecoveryServicesBackupProtectionPolicy -Name $policyName -VaultId $vault.ID

# Enable backup
Enable-AzRecoveryServicesBackupProtection `
    -Policy $policy `
    -Name $vmName `
    -ResourceGroupName $vmResourceGroup `
    -VaultId $vault.ID
```

Save this script as `Enable-VMBackup.ps1` in the `scripts` folder and run as needed.

## Files Structure

- `main.bicep`: Main infrastructure as code template
- `modules/`: Bicep modules for vault and policy
  - `recoveryVault.bicep`: Recovery Services Vault module
  - `backupPolicy.bicep`: Backup policy configuration module
- `scripts/`: PowerShell scripts for deployment
  - `Create-ResourceGroup.ps1`: Creates resource group if not exists
  - `Deploy-Backup.ps1`: Deploys the Bicep template
  - `Set-DeploymentParameters.ps1`: Sets deployment parameters
  - `Enable-VMBackup.ps1`: Optional script for automated VM backup enablement
- `azure-pipelines.yml`: Azure DevOps pipeline definition