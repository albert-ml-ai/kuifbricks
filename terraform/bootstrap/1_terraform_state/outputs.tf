# These outputs are used in backend configuration of other Terraform roots
# Backend configuration is for remote state storage in Azure Blob Storage
output "resource_group_name" {
  description = <<-EOT
    Resource group containing the Terraform state backend.
    This value must match resource_group_name in the azurerm backend
    configuration of each Terraform root.
  EOT

  value = azurerm_resource_group.terraform_state.name
}

output "storage_account_name" {
  description = <<-EOT
    Storage account used for remote Terraform state storage.
    This value must match storage_account_name in the azurerm backend
    configuration of each Terraform root.
  EOT

  value = azurerm_storage_account.terraform_state.name
}

output "container_name" {
  description = <<-EOT
    Blob container used for remote Terraform state storage.
    This value must match container_name in the azurerm backend configuration
    of each Terraform root. Only the backend key should differ per root.
  EOT

  value = azurerm_storage_container.terraform_state.name
}
