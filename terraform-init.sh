#!/bin/bash

# Terraform Init Script with Backend Configuration
# Usage: ./terraform-init.sh [tfvars-file]

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

echo "Initializing Terraform with backend configuration..."
echo "Resource Group: ${VARS[terraform_state_store_resource_group]}"
echo "Storage Account: ${VARS[terraform_state_store_storage_account]}"
echo "Container: ${VARS[container_name]}"

# Run terraform init with backend configuration
terraform init \
    -backend-config="resource_group_name=${VARS[terraform_state_store_resource_group]}" \
    -backend-config="storage_account_name=${VARS[terraform_state_store_storage_account]}" \
    -backend-config="container_name=${VARS[container_name]}" \
    -backend-config="key=${VARS[resource_group]}.tfstate"

echo "Terraform initialization complete!"
