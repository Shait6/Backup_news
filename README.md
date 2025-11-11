# Azure VM Backup Automation (short)

Purpose
- Deploy Recovery Services Vault and backup policy to a subscription, then optionally audit and auto-enable backup for tagged VMs.

Prerequisites
- Azure subscription where the deployment will run (Owner/Contributor or equivalent RBAC).
- Azure DevOps service connection with access to the target subscription.

Quick usage
1. Run the pipeline and set:
   - `subscriptionId` — target subscription
   - `location` — region
   - `vaultName` / `vaultResourceGroup` — vault to use (or set `createVault=true` to create one)
   - `backupFrequency` — `Daily`, `Weekly`, or `Both`
   - `backupRetentionDays` — integer (days)
   - `enableAutoRemediation` — `true` to deploy DeployIfNotExists remediation (optional)

What DeployIfNotExists does
- For VMs tagged with the configured tag (default `backup=true`) the policy will detect missing backup protection and automatically deploy a remediation deployment that links the VM to the specified Recovery Services vault and backup policy using ARM (no Automation Account required).

Notes & permissions
- The remediation runs via Azure Policy / ARM using a managed identity and requires the ability to create policy definitions/assignments and to create the necessary protected item in the target subscription. Ensure the service principal has the necessary RBAC.
- If you choose `createVault=true` the pipeline will create the vault in the given resource group.

Files (high level)
- `main.bicep`: deploys vault and backup policy
- `modules/`: reusable Bicep modules (vault, policy, audit, auto-enable)
- `scripts/`: deployment helpers and optional scripts
- `azure-pipelines.yml`: pipeline that orchestrates deployment and optional auto-remediation

For details on the policy behavior and parameters, see the Bicep modules under `modules/`.

## Audit pipeline (optional)
The audit policy deployment is now separated into its own pipeline so you can run audits on-demand without changing the main infra pipeline.

- Main pipeline: `azure-pipelines.yml` — deploys vault, backup policies and (optionally) auto-remediation.
- Audit pipeline: `azure-pipelines-audit.yml` — deploys the audit policy and assignment at the management group scope.

How to run the audit pipeline
1. Create a pipeline in Azure DevOps pointing to `azure-pipelines-audit.yml`.
2. Provide `managementGroupId`, `vmTagName` and `vmTagValue` parameters (e.g., `backup` / `true`).
3. Run the pipeline when you want to scan for unprotected VMs across the management group.

Notes
- Splitting the audit out keeps the main deployment focused on infra and remediation. It also makes it easier to schedule or run audits manually on a cadence you choose.

## Example pipeline parameters (one-step)
Use these example values in the pipeline for a common scenario: create a new vault in `rg-vmbackup-default` and enable auto-remediation for VMs tagged `backup=true`.

- `subscriptionId`: <your-subscription-id>
- `location`: westeurope
- `resourceGroupName`: rg-vmbackup-default
- `vaultName`: rsv-backup-default
- `vaultResourceGroup`: rg-vmbackup-default
- `createVault`: true
- `backupPolicyName`: DefaultPolicy
- `backupFrequency`: Both
- `backupRetentionDays`: 14
- `vmTagName`: backup
- `vmTagValue`: true
- `enableAutoRemediation`: true

Vault SKU
- `vaultSkuName`: Recovery Services Vault SKU name (default: `RS0`)
- `vaultSkuTier`: Recovery Services Vault SKU tier (default: `Standard`)



## Dry-run validation (build + WhatIf)
Before running the pipeline in production, validate the Bicep templates locally and perform a subscription-scoped WhatIf to confirm no unexpected resources will be created.

1) Open PowerShell in the repository root (Windows PowerShell or PowerShell Core).

2) Check for Bicep availability and Azure CLI:

```powershell
# Check local bicep CLI (optional)
Get-Command bicep -ErrorAction SilentlyContinue

# If using Azure CLI's bicep support
az bicep version

# Check Az PowerShell module (optional)
Get-Module -ListAvailable Az
```

3) Build the Bicep file to JSON so you can validate the ARM template:

```powershell
# From repo root
bicep build .\main.bicep --outdir .\compiled
# OR, if you prefer the Azure CLI wrapper:
az bicep build --file .\main.bicep --outdir .\compiled
```

4) Perform a subscription-scoped WhatIf validation (requires Az PowerShell module and you must be signed in):

```powershell
# Sign in and select subscription
Connect-AzAccount
Select-AzSubscription -SubscriptionId '<your-subscription-id>'

# Run subscription deployment validation (WhatIf). Replace location and template path as needed.
New-AzSubscriptionDeployment -Name 'backup-deploy-validate' -Location 'westeurope' -TemplateFile .\compiled\main.json -WhatIf
```

Notes:
- `-WhatIf` will simulate the deployment and list actions without making changes. For subscription deployments, choose an allowed location for subscription-level deployments (e.g., `westeurope`).
- If `bicep` is not installed, install it via the Azure CLI `az bicep install` or follow https://learn.microsoft.com/azure/azure-resource-manager/bicep/install.

## Quick test for DeployIfNotExists remediation
1. Deploy the pipeline with `enableAutoRemediation=true` and `createVault=true` (or point to an existing vault).
2. Tag a test VM in the target subscription with the configured tag, for example `backup=true`.
3. In the Azure portal, check Azure Policy -> Assignments and find the assigned DeployIfNotExists policy. After the policy runs, check Compliance and Remediations for the assignment.
4. The remediation will try to create the protectedItem in the Recovery Services vault linking the VM to the backup policy. Confirm the VM shows as protected in the Recovery Services vault -> Backup items.

Note about `Both` backup frequency
- If you choose `backupFrequency = Both`, the deployment creates two policies named `<backupPolicyName>-daily` and `<backupPolicyName>-weekly`.
- The auto-remediation job (DeployIfNotExists) accepts a single `backupPolicyName` parameter. When using `Both`, set the pipeline `backupPolicyName` parameter to the exact policy you want remediation to use (for example `DefaultPolicy-daily` or `DefaultPolicy-weekly`).

If you want, I can attempt a local `bicep build` now and report results (I will run the build in your workspace and show the output). Say "Yes — run the build now" and I'll run it and report back.