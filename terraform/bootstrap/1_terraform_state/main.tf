/*
  This Terraform configuration bootstraps the Azure Storage backend used by
  the other Terraform root modules in the kuifbricks repository.

  It creates:
  - A dedicated Azure resource group
  - A standard Azure Storage account
  - A private blob container for Terraform state files
  - Versioning and soft-delete protection
  - Storage Blob Data Contributor access for the identity running bootstrap

  This root module initially uses local Terraform state because the remote
  backend does not exist yet. Other Terraform roots can use the created
  container after this bootstrap configuration has been applied.

  LRS (local redundant storage) is used here, for small files, in this showcase repo.

  Each Terraform root uses a separate backend key, for example:
  - github/github.tfstate
  - azure/azure.tfstate
  - bootstrap/terraform_cicd_identity/terraform.tfstate
*/

data "azurerm_client_config" "current" {}

resource "azurerm_resource_group" "terraform_state" {
  name     = var.resource_group_name
  location = var.azure_location

  tags = {
    application = "kuifbricks"
    purpose     = "terraform-state"
    managed-by  = "terraform"
  }
}

resource "azurerm_storage_account" "terraform_state" {
  name                = var.storage_account_name
  resource_group_name = azurerm_resource_group.terraform_state.name
  location            = azurerm_resource_group.terraform_state.location

  account_kind             = "StorageV2"
  account_tier             = "Standard"
  account_replication_type = "LRS"

  min_tls_version                 = "TLS1_2"
  https_traffic_only_enabled      = true
  public_network_access_enabled   = true
  allow_nested_items_to_be_public = false

  blob_properties {
    versioning_enabled = true

    delete_retention_policy {
      days = 7
    }

    container_delete_retention_policy {
      days = 7
    }
  }

  tags = {
    application = "kuifbricks"
    purpose     = "terraform-state"
    managed-by  = "terraform"
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "azurerm_storage_container" "terraform_state" {
  name                  = "tfstate"
  storage_account_id    = azurerm_storage_account.terraform_state.id
  container_access_type = "private"
}

# Azure management roles such as Contributor do not automatically grant access
# to blob data. This assignment allows the identity running the bootstrap to
# read, write and lock Terraform state through Microsoft Entra authentication.
resource "azurerm_role_assignment" "terraform_state_current_user" {
  scope                = azurerm_storage_account.terraform_state.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = data.azurerm_client_config.current.object_id
}
