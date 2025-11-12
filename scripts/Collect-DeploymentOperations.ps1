param(
  [Parameter(Mandatory=$true)]
  [string]$SubscriptionId,
  [Parameter(Mandatory=$true)]
  [string]$ResourceGroupName,
  [Parameter(Mandatory=$false)]
  [string]$DeploymentName = 'main'
)

az account set --subscription $SubscriptionId

Write-Host "Collecting deployment operations for deployment '$DeploymentName' in resource group '$ResourceGroupName'..."

$ops = az deployment group operation list --resource-group $ResourceGroupName --name $DeploymentName -o json
if (-not $ops) {
  Write-Host "No operations returned."
  exit 0
}

$opsPath = "ops.json"
$ops | Out-File -FilePath $opsPath -Encoding utf8
Write-Host "Wrote $opsPath"

# Parse operations and write details for failed operations
$opsObj = $ops | ConvertFrom-Json
$failed = $opsObj | Where-Object { $_.properties.provisioningState -ne 'Succeeded' }
if (-not $failed -or $failed.Count -eq 0) {
  Write-Host "No failed operations found."
  exit 0
}

foreach ($f in $failed) {
  $opId = $f.operationId -replace '[^a-zA-Z0-9-]',''
  $file = "op-$opId.json"
  az deployment group operation show --resource-group $ResourceGroupName --name $DeploymentName --operation-ids $f.operationId -o json > $file
  Write-Host "Wrote $file"
}

Write-Host "Done collecting failed operations."
