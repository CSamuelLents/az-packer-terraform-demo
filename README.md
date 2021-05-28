# Deploy a scalable IaaS web server in Azure <!-- omit in toc -->

- [Introduction](#introduction)
- [Getting Started](#getting-started)
- [Dependencies](#dependencies)
- [Instructions](#instructions)
  - [Creating an Azure Resource Group](#creating-an-azure-resource-group)
  - [Creating an Azure Policy](#creating-an-azure-policy)
  - [Building & Deploying the Packer Image](#building--deploying-the-packer-image)
  - [Deploying the Infrastructure](#deploying-the-infrastructure)
  - [Customizing the Deployment](#customizing-the-deployment)
- [Output](#output)

## Introduction

This project provides Packer and Terraform templates for deploying a customizable, scalable Ubuntu web server on the Microsoft Azure cloud. Follow the steps in [Getting Started](#getting-started) if you're comfortable with the [toolset](#dependencies), or see the [Instructions](#instructions) section for a more detailed walkthrough.

## Getting Started

The following assumes you've installed and configured required dependencies, listed [below](#dependencies).

1. Clone the repository
2. Create an Azure resource group for your Packer image and infrastructure
3. Deploy an (optional) Azure Policy requiring resource tags
4. Build and deploy the Packer image
5. Import your resource group using the Terraform CLI
6. Deploy the infrastructure using Terraform

## Dependencies

1. Create an [Azure Account](https://portal.azure.com)
2. Install the [Azure command line interface](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest)
3. Install [Packer](https://www.packer.io/downloads)
4. Install [Terraform](https://www.terraform.io/downloads.html)

## Instructions

### Creating an Azure Resource Group

The resource group should be created before running `packer build server.json`, as the image will need a destination. You can do this in two ways:

1. Comment out everything in `main.tf` after the resource group block (after line 12) and everything in `outputs.tf`, and follow the instructions under [Deploying the Infrastructure](#deploying-the-infrastructure) below to deploy the resource group. Once completed, build and deploy the Packer image, uncomment the Terraform templates, and run the Terraform plan/deploy steps again.

2. Create the resource group manually in Azure, set the `ARM_SUBSCRIPTION_ID` and `ARM_RESOURCE_GROUP` variables in your environment and run the provided `import-resource-group.sh` script to import the resource into your Terraform state. The `azurerm_resource_group` resource in `main.tf` should remain as is.

### Creating a Tagging Policy

1. Navigate to your subscription in Azure
2. Select `Policies` from the sidebar navigation
3. Select `Assign policy` from the inline navigation
4. Under the `Policy definition` field, search for and select the builtin `Require a tag on resources` policy
5. Fill out other fields as desired

### Building & Deploying the Packer Image

1. Initialize your environment with the following variables from your Azure account

   ```bash
   export ARM_CLIENT_ID=<YOUR_ARM_CLIENT_ID>
   export ARM_CLIENT_SECRET=<YOUR_ARM_CLIENT_SECRET>
   export ARM_SUBSCRIPTION_ID=<YOUR_ARM_SUBSCRIPTION_ID>
   ```

2. Run `packer build server.json`

### Deploying the Infrastructure

1. Run `terraform apply "solution.plan"` from the commandline
2. Input values for variables as prompted by your terminal
3. Respond with `yes` when prompted for pre-deployment confirmation

### Customizing the Deployment

The deployment can be customized by updating the values found in `vars.tf`. Of particular interest may be `location`, `vm_size`, and `vm_count`.

## Output

The Terraform templates output the following:

- VM hostname (`hostname`)
- VM Fully Qualified Domain Name (`vm_fqdn`)
- VM RDP address (`vms_rdp_access`)
