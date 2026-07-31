# This variable is used to connect to the Azure subscription
variable "azure_subscription_id" {
  description = "The Azure subscription ID where the resources will be created."
  type        = string
  nullable    = false

  validation {
    condition     = length(trimspace(var.azure_subscription_id)) > 0
    error_message = "azure_subscription_id must not be empty."
  }
}

variable "azure_location" {
  description = "The Azure region where the resources will be created."
  type        = string
  default     = "westeurope"
  nullable    = false

  validation {
    condition     = length(trimspace(var.azure_location)) > 0
    error_message = "azure_location must not be empty."
  }
}

variable "resource_group_name" {
  description = "The name of the resource group to create for storing Terraform state."
  type        = string
  default     = "kuifbricks-terraform-state"
  nullable    = false

  validation {
    condition     = can(regex("^[A-Za-z0-9._-]+$", var.resource_group_name))
    error_message = "resource_group_name may only contain letters, numbers, dots, underscores, and hyphens."
  }
}

variable "storage_account_name" {
  description = "The name of the storage account to create for storing Terraform state."
  type        = string
  default     = "kuifbrickstfstate"
  nullable    = false

  validation {
    condition     = can(regex("^[a-z0-9]{3,24}$", var.storage_account_name))
    error_message = "storage_account_name must be between 3 and 24 characters, and may only contain lowercase letters and numbers."
  }
}
