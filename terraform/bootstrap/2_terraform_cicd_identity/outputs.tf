output "azure_client_id" {
  description = "Set as GitHub Actions variable AZURE_CLIENT_ID."
  value       = azuread_application.terraform_cicd.client_id
}

output "azure_tenant_id" {
  description = "Set as GitHub Actions variable AZURE_TENANT_ID."
  value       = data.azuread_client_config.current.tenant_id
}

output "azure_subscription_id" {
  description = "Set as GitHub Actions variable AZURE_SUBSCRIPTION_ID."
  value       = var.azure_subscription_id
}
