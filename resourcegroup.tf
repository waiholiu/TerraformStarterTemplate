# This file defines the default Azure resource group. You shouldn't need to edit this file unless you want the resource group to be different to your state store file

resource "azurerm_resource_group" "example" {
  name     = var.resource_group
  location = var.location
}