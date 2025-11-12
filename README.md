# Azure VM Backup Automation

This repository provides automated deployment of Recovery Services Vault(s) and Backup Policy(ies) for Azure VMs, plus an optional DeployIfNotExists policy that can automatically enable backup for VMs that match a tag (for example `backup=true`). The project is designed to run from either GitHub Actions or Azure DevOps pipelines.

## What this solution does (high level)
- Generates deployment parameters and normalizes values (schedule times, weekly days, retention counts).
- Validates and compiles Bicep templates (pre-check) to catch template/schema issues early.
- Deploys a Recovery Services Vault and one or more backup policies (Daily, Weekly or Both) into a resource group and location you choose.
- Optionally deploys a subscription-scoped DeployIfNotExists policy that detects unprotected VMs with a specific tag and remediates them by enabling backup with the chosen policy.

## Main files and what they do (short)
- `main.bicep` — Orchestrator: calls modules to create the Recovery Services vault and backup policy resources.
- `main.parameters.json` — Generated parameters file created by `scripts/Set-DeploymentParameters.ps1` and consumed by `az deployment`.
- `modules/` — Bicep modules used by the orchestrator:
	- `recoveryVault.bicep` — creates or references the Recovery Services Vault.
	- `backupPolicy.bicep` — creates Daily / Weekly / Both backup policy resources and outputs policy names/IDs.
	- `backupAutoEnablePolicy.bicep` / `autoEnablePolicy.rule.json` — policy definition template/JSON used for DeployIfNotExists automation; the workflow pre-processes placeholders before calling `az policy`.
- `scripts/` — helper scripts:
	- `Set-DeploymentParameters.ps1` — builds `main.parameters.json`, validates/normalizes schedule times and weekly days, and ensures daily/weekly retention values are present.
	- `Create-ResourceGroup.ps1` — creates the target resource group.
	- `Deploy-Backup.ps1` — wrapper used by ADO to perform the deployment via Az/CLI.
	- `Deploy-AutoEnablePolicySubscription.ps1` / `Deploy-AuditPolicy.ps1` — scripts to create policy definitions/assignments for remediation or audit.
- CI workflows/pipelines:
	- `.github/workflows/deploy.yml` — GitHub Actions workflow: prepares parameters, runs `az bicep build` pre-check, validates, deploys resources, and optionally deploys the auto-enable policy.
	- `azure-pipelines.yml` — Azure DevOps pipeline: same overall flow adapted to ADO tasks; publishes/downloads the generated `main.parameters.json` between jobs and runs a validate pre-check.
	- `azure-pipelines-audit.yml` — optional audit pipeline for management-group scoped audits.

## Prerequisites
Common
- An Azure subscription. The identity used by CI must have permissions to create resource groups, vaults and backup policies. If you will create policy definitions/assignments, the identity also needs Policy Contributor or Owner.
- Azure CLI (`az`) available on the runner or Az PowerShell for ADO tasks that use it. The workflows install `az bicep` if missing.

For GitHub Actions
- A secret containing service principal credentials (JSON) configured for `azure/login` (the repo uses `${{ secrets.serivcon }}` by default). The SP must have the RBAC noted above.
- The workflow runs on `windows-latest` and uses `pwsh` for parameter generation and validation; the deployment step runs in `bash` to avoid PowerShell splatting issues.

For Azure DevOps
- A service connection (Azure Resource Manager) backed by a service principal with the required permissions. The pipeline uses `AzurePowerShell@5` and `AzureCLI@2` tasks.

## Important behavior and gotchas
- Location must be consistent: pick the workflow/pipeline `location` input and ensure it's passed to resource group creation and included in `main.parameters.json` so the vault and RG are created in the same region. The GitHub workflow now passes `-IncludeLocation` to the parameter script by default.
- PowerShell quoting: when calling `az ... --parameters @main.parameters.json` from PowerShell, quote the file string (e.g., `--parameters "@main.parameters.json"`) to avoid PowerShell interpreting `@` as a splat operator. The workflows include a PowerShell-safe validate step.
- Policy creation and remediation permissions: creating/updating policy definitions and assigning them at subscription or management-group scope requires Policy Contributor or Owner privileges. If the service principal lacks those permissions the policy steps will fail even if the template deploys successfully.
- `backupFrequency = Both` creates two concrete backup policies: `<policyName>-daily` and `<policyName>-weekly`. If using the auto-remediation policy, point remediation at a specific policy name (for example `DefaultPolicy-daily`) because remediation expects a single policy name to apply.

## Quick local validation (recommended before deploy)
1) Regenerate the parameters file (PowerShell):

```powershell
.\scripts\Set-DeploymentParameters.ps1 `
	-Location 'eastus' `
	-SubscriptionId '<SUB_ID>' `
	-VaultName 'rsv-backup-test' `
	-BackupPolicyName 'DefaultPolicy' `
	-DailyRetentionDays 14 `
	-WeeklyRetentionDays 30 `
	-BackupScheduleRunTimes @('01:00') `
	-WeeklyBackupDaysOfWeek @('Sunday','Wednesday') `
	-IncludeLocation
```

2) Validate the deployment with PowerShell-safe parameters quoting:

```powershell
az account set --subscription <SUB_ID>
az deployment group validate --resource-group <RG_NAME> --template-file main.bicep --parameters "@main.parameters.json"
```

If validation fails, copy the CLI output (the provider `statusMessage` JSON) and paste it into an issue or here — that message pinpoints the exact property Azure rejects (schedule time, days, retention schema, etc.).

## Running in CI
- GitHub Actions: dispatch `deploy.yml` from the Actions UI or trigger via workflow_dispatch. Supply `subscriptionId`, `location`, `resourceGroupName` and other inputs shown in the workflow. The workflow will produce artifacts (compiled Bicep template and resolved policy JSON) and run a validate step before deployment.
- Azure DevOps: run the `azure-pipelines.yml` pipeline with equivalent parameters. The pipeline publishes `main.parameters.json` from the PrepareParameters job and downloads it in the Deploy job to run `az deployment group validate` before the actual deployment.

## Audit pipeline
The audit policy deployment is separated into `azure-pipelines-audit.yml` so you can run audits at management-group scope without affecting the main infra pipeline. Use it to detect unprotected VMs across your management group and optionally run remediation separately.

## Need help diagnosing a validation error?
- Run the local validation command above and copy the JSON `statusMessage` from a failed validation. Paste it here and I will identify which property/formattings the Recovery Services API expects and propose a precise fix.

--
If you want, I can also add a short `USAGE.md` with ready-to-paste GitHub Actions dispatch examples and Azure DevOps pipeline run examples — tell me which and I will add it.
