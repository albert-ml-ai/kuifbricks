data "azuread_client_config" "current" {}

resource "azuread_application" "terraform_cicd" {
  display_name = "kuifbricks-terraform-cicd"

  owners = [
    data.azuread_client_config.current.object_id
  ]
}

resource "azuread_service_principal" "terraform_cicd" {
  client_id = azuread_application.terraform_cicd.client_id

  owners = [
    data.azuread_client_config.current.object_id
  ]
}

resource "azuread_application_federated_identity_credential" "github" {
  application_id = azuread_application.terraform_cicd.id
  display_name   = "github-actions"
  description    = "Allow GitHub Actions to authenticate to Azure using OIDC."
  audiences      = ["api://AzureADTokenExchange"]
  issuer         = "https://token.actions.githubusercontent.com"

  subject = "repo:${var.github_owner}/${var.repository_name}:ref:refs/heads/main"
}

resource "azuread_application_federated_identity_credential" "github_pr" {
  application_id = azuread_application.terraform_cicd.id
  display_name   = "github-actions-pr"
  description    = "Allow GitHub Actions PR checks to authenticate to Azure using OIDC."
  audiences      = ["api://AzureADTokenExchange"]
  issuer         = "https://token.actions.githubusercontent.com"

  subject = "repo:${var.github_owner}/${var.repository_name}:pull_request"
}

data "azurerm_storage_account" "terraform_state" {
  name                = var.tfstate_storage_account_name
  resource_group_name = var.tfstate_resource_group_name
}

# Storage Blob data-plane access is not granted by Contributor
# To read and write tfstate files, a data plane role is assigned
resource "azurerm_role_assignment" "terraform_cicd_state" {
  scope                = data.azurerm_storage_account.terraform_state.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azuread_service_principal.terraform_cicd.object_id
}

# Contributor role since it will manage various infrastructure resources
resource "azurerm_role_assignment" "terraform_cicd_contributor" {
  scope                = "/subscriptions/${var.azure_subscription_id}"
  role_definition_name = "Contributor"
  principal_id         = azuread_service_principal.terraform_cicd.object_id
}

# later we will need to add role assignment for access management
