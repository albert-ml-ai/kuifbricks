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

# These variables are used to refer to the GitHub repository and its branch.
variable "github_owner" {
  description = "GitHub user or organization that owns the repository."
  type        = string
  nullable    = false

  validation {
    condition     = length(trimspace(var.github_owner)) > 0
    error_message = "github_owner must not be empty."
  }
}

variable "repository_name" {
  description = "Name of the GitHub repository."
  type        = string
  default     = "kuifbricks"
  nullable    = false

  validation {
    condition     = can(regex("^[A-Za-z0-9._-]+$", var.repository_name))
    error_message = "repository_name may only contain letters, numbers, dots, underscores, and hyphens."
  }
}

variable "tfstate_resource_group_name" {
  description = "Resource group of the Terraform state storage account created in bootstrap/1_terraform_state."
  type        = string
  default     = "kuifbricks-terraform-state"
  nullable    = false

  validation {
    condition     = length(trimspace(var.tfstate_resource_group_name)) > 0
    error_message = "tfstate_resource_group_name must not be empty."
  }
}

variable "tfstate_storage_account_name" {
  description = "Storage account name created in bootstrap/1_terraform_state."
  type        = string
  default     = "kuifbrickstfstate"
  nullable    = false

  validation {
    condition     = can(regex("^[a-z0-9]{3,24}$", var.tfstate_storage_account_name))
    error_message = "tfstate_storage_account_name must be 3-24 lowercase letters and numbers."
  }
}
