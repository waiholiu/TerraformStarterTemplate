#!/bin/bash

# Simple Azure CLI script to create Terraform state storage
# Usage: ./create-storage.sh [tfvars-file]

TFVARS_FILE="${1:-variables.tfvars}"

# Function to parse tfvars file and extract variable values
parse_tfvars() {
    local file="$1"
    local var_name="$2"
    grep "^${var_name}[[:space:]]*=" "$file" | sed 's/.*=[[:space:]]*"\(.*\)".*/\1/' | tr -d '"'
}

# Automatically detect all variables from tfvars file
declare -A VARS
while IFS= read -r line; do
    if [[ $line =~ ^[[:space:]]*([a-zA-Z_][a-zA-Z0-9_]*)[[:space:]]*= ]]; then
        var_name="${BASH_REMATCH[1]}"
        VARS[$var_name]=$(parse_tfvars "$TFVARS_FILE" "$var_name")
    fi
done < "$TFVARS_FILE"

az account set --subscription "${VARS[subscription_id]}"
az group create --name "${VARS[terraform_state_store_resource_group]}" --location "${VARS[location]}"
az group lock create --name "terraform-state-lock" --resource-group "${VARS[terraform_state_store_resource_group]}" --lock-type CanNotDelete
az storage account create --name "${VARS[terraform_state_store_storage_account]}" --resource-group "${VARS[terraform_state_store_resource_group]}" --location "${VARS[location]}" --sku Standard_LRS --https-only true --allow-blob-public-access false
az storage container create --name "${VARS[container_name]}" --account-name "${VARS[terraform_state_store_storage_account]}" --auth-mode login

echo "Storage account created: ${VARS[terraform_state_store_storage_account]}"
