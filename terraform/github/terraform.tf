terraform {
  required_version = "~> 1.15.0"

  backend "azurerm" {
    resource_group_name  = "kuifbricks-terraform-state"
    storage_account_name = "kuifbrickstfstate"
    container_name       = "tfstate"
    key                  = "github/github.tfstate"
    use_azuread_auth     = true
  }

  required_providers {
    github = {
      source  = "integrations/github"
      version = "~> 6.0"
    }
  }
}
