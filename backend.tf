# Add this to main.tf or create backend.tf
terraform {
  backend "azurerm" {
    # Configuration provided via terraform-init.sh
  }
}