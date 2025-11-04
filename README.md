# Azure VM Backup Automation

This solution provides an automated way to deploy and configure VM backup across multiple subscriptions in an Azure tenant using Azure Recovery Services Vault and Azure DevOps pipelines.

## Features

- Deploys Recovery Services Vault in specified regions
- Configures backup policies with customizable retention and schedule
- Supports multiple regions (West Europe, North Europe, Sweden Central, Germanywestcentral)
- Uses Azure DevOps pipeline with parameters for flexible deployment
- Supports Hub and Spoke network model

## Prerequisites

1. Azure DevOps project with necessary permissions
2. Service Principal with required permissions in target subscriptions
3. Azure Service Connection configured in Azure DevOps

## How to Use

1. Clone this repository to your Azure DevOps project
2. Create a service connection named 'Azure-ServiceConnection' in your Azure DevOps project
3. Customize the parameters in `main.parameters.json` if needed
4. Run the pipeline with the following parameters:
   - Select target region
   - Enable/Disable backup
   - Specify subscription ID

## Pipeline Parameters

- `subscriptionId`: Target subscription ID
- `location`: Target region (westeurope, northeurope, swedencentral, germanywestcentral)
- `enableBackup`: Boolean flag to enable/disable backup deployment

## Backup Configuration

- Default backup schedule: Weekly on Sunday and Wednesday
- Default retention period: 30 days
- Customizable through parameters file

## Security Features

- Public network access can be disabled
- Cross-subscription restore enabled by default
- Standard tier storage redundancy

## Files Structure

- `main.bicep`: Main infrastructure as code template
- `main.parameters.json`: Parameters for the Bicep template
- `azure-pipelines.yml`: Azure DevOps pipeline definition