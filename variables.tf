variable "env" {
    description = "The environment in which the resources will be created"
    type        = string
}

variable "resource_group" {
    description = "The environment in which the resources will be created"
    type        = string
}

variable "subscription_id" {
    description = "The environment in which the resources will be created"
    type        = string
}

variable "unique" {
    description = "The environment in which the resources will be created"
    type        = string
}

variable "terraform_state_store_resource_group" {
    description = "Resource group for Terraform state storage"
    type        = string
}

variable "terraform_state_store_storage_account" {
    description = "Storage account name for Terraform state"
    type        = string
}

variable "location" {
    description = "Azure region/location for all resources"
    type        = string
    default     = "australiaeast"
}

variable "container_name" {
    description = "Container name for Terraform state files"
    type        = string
    default     = "tfstate"
}


