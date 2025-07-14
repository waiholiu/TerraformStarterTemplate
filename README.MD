# What is this?

This is a starter template for managing Azure resources using Terraform. In Terraform, there is often a weird chicken and egg problem where you need to create a storage account to store the Terraform state store which you can't use Terraform for because well... you don't have a state store yet. This template has a re-entrant bootstrap file that creates the storage account using azure cli. 

It also uses the variables.tfvars file that can be used in both bash scripts and Terraform configuration files. This allows you to have a single source of truth for your variables, and to ensure there is a common standard so that you have all your state store resources in one place corresponding to the resource group name.

This template really is designed for 

# Prequisites

- Have terraform and az cli installed etc.
- use az login to log in and have the necessary permissions to create resources.


# How to use

1. Edit the `variables.tfvars` file to set your Azure subscription ID and resource group names. 
2. Run the `bootstrap.sh` script to create the initial storage account and resource group.
3. Use `./terraform-init.sh` to initialize Terraform.
4. Write your tf configuration in main.tf and other files as required
5. Run `terraform apply -var-file="variables.tfvars"` to deploy your resources.
6. To destroy all resources, run `./terraform-destroy.sh`.

# What each file does

## `variables.tfvars`: 
Contains variables for your Azure subscription ID and resource group names and optionally, you can add variables for your terraform configuration. Each bash script below also has some code in the beginning to change the variables in this file to be bash variables so that you can have one single variable file that is referenced for both terraform and bash.

For me, I would likely just edit resource_group and subscription to be the where you want to deploy your app into and keep all the other variables the same across all my projects. However, this is because I want to keep all my Terraform state store resources in one place.

## `main.tf`: 
Contains the a sample Terraform configuration for your Azure resources. Edit this and add your own resources as needed.
## `bootstrap.sh`: 
A script to create the initial storage account and resource group using Azure CLI for the Terraform State Store. It'll put a lock on this resource group as it's not intended to be deleted and you'll be sharing this storage account with other terraform projects deployed in the same subscription. This is a one-time setup script that you run before using Terraform but you can run it as many times as you want without breaking anything. 

## `terraform-init.sh`: 
Initializes Terraform specifying the backend to have the state store be the storage account created by `bootstrap.sh`. It also will create a state store file in the the storage account as the resource group name specified in `variables.tfvars`. 

## `terraform-destroy.sh`: 
A script to destroy all resources created by Terraform, using the variables from `variables.tfvars`. It also deletes the Terraform state store file.


# Multiple deployments
 If you have multiple deployments for your application, you can have multiple variables.tfvars files, one for each deployment. Just make sure to change the resource group name in each variables.tfvars file so that they don't conflict with each other. Also, by default, all the other files will reference the `variables.tfvars` file in the same directory as the script so you'll need to rename the right file to be variables.tfvars and re-run terraform-init.sh before running the scripts.