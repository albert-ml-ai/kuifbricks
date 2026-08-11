terraform {
  required_version = "~> 1.15.0"

  backend "azurerm" {
    resource_group_name  = "kuifbricks-terraform-state"
    storage_account_name = "kuifbrickstfstate"
    container_name       = "tfstate"
    key                  = "terraform_cicd_entity/terraform_cicd_entity.tfstate"
    use_azuread_auth     = true
  }

  required_providers {
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 3.9"
    }

    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}