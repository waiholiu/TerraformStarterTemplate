#!/bin/bash

# Terraform Destroy Script with State File Cleanup
# Usage: ./terraform-destroy.sh [tfvars-file]

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

echo "=========================================="
echo "Terraform Destroy Script"
echo "Using tfvars file: $TFVARS_FILE"
echo "=========================================="

# Step 1: Show what will be destroyed
echo "Step 1: Creating destruction plan..."
terraform plan -destroy -var-file="$TFVARS_FILE" -out=destroyplan
if [ $? -ne 0 ]; then
    echo "❌ Terraform destroy plan failed!"
    exit 1
fi
echo "✅ Destroy plan created successfully"

# Step 2: Confirm destruction
echo ""
echo "Step 2: Confirming destruction..."
echo "This will destroy the following infrastructure:"
echo "  - Resource Group: ${VARS[resource_group]}"
echo "  - All resources within that resource group"
echo ""
echo "The state file will also be deleted from:"
echo "  - Storage Account: ${VARS[terraform_state_store_storage_account]}"
echo "  - Container: ${VARS[container_name]}"
echo "  - File: ${VARS[resource_group]}.tfstate"
echo ""
read -p "Are you sure you want to destroy everything? (y/N): " -n 1 -r
echo

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ Destroy cancelled by user"
    rm -f destroyplan
    exit 0
fi

# Step 3: Destroy infrastructure
echo ""
echo "Step 3: Destroying infrastructure..."
terraform apply destroyplan
if [ $? -ne 0 ]; then
    echo "❌ Terraform destroy failed!"
    exit 1
fi
echo "✅ Infrastructure destroyed successfully"

# Step 4: Delete state file from Azure Storage
echo ""
echo "Step 4: Deleting state file from Azure Storage..."
STATE_FILE_NAME="${VARS[resource_group]}.tfstate"

# Check if state file exists
if az storage blob exists \
    --account-name "${VARS[terraform_state_store_storage_account]}" \
    --container-name "${VARS[container_name]}" \
    --name "$STATE_FILE_NAME" \
    --auth-mode login \
    --query exists \
    --output tsv | grep -q "true"; then
    
    echo "Deleting state file: $STATE_FILE_NAME"
    
    # Delete the state file
    if az storage blob delete \
        --account-name "${VARS[terraform_state_store_storage_account]}" \
        --container-name "${VARS[container_name]}" \
        --name "$STATE_FILE_NAME" \
        --auth-mode login; then
        echo "✅ State file deleted successfully"
    else
        echo "⚠️  Warning: Failed to delete state file (it may not exist)"
    fi
else
    echo "ℹ️  State file does not exist or already deleted"
fi

# Step 5: Cleanup local files
echo ""
echo "Step 5: Cleaning up local files..."
rm -f destroyplan
rm -f terraform.tfstate terraform.tfstate.backup
rm -rf .terraform

echo ""
echo "=========================================="
echo "🎉 Destruction Complete!"
echo "=========================================="
echo ""
echo "Destroyed:"
echo "  ✅ Infrastructure resources"
echo "  ✅ State file: $STATE_FILE_NAME"
echo "  ✅ Local Terraform files"
echo ""
echo "Preserved:"
echo "  ✅ Storage Account: ${VARS[terraform_state_store_storage_account]}"
echo "  ✅ Container: ${VARS[container_name]}"
echo "  ✅ Resource Group: ${VARS[terraform_state_store_resource_group]}"
echo ""
echo "To redeploy, run:"
echo "  ./terraform-init.sh"
echo "  terraform apply -var-file=\"$TFVARS_FILE\""
