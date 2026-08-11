# These variables are used to configure the GitHub repository and its settings.
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

variable "repository_description" {
  description = "Description shown on the GitHub repository page."
  type        = string
  default     = "This Azure Databricks monorepo showcases best practices for building and operating data and ML platforms on Azure Databricks. It is designed to be modular and extensible, so you can use it as a starting point for your own projects."
  nullable    = false
}

variable "repository_topics" {
  description = "Topics attached to the GitHub repository."
  type        = set(string)

  default = [
    "azure",
    "azure-databricks",
    "ci-cd",
    "data-engineering",
    "databricks",
    "databricks-asset-bundles",
    "dbt",
    "github-actions",
    "python",
    "terraform",
  ]
}

# This variable facilitates initial repository bootstrap without branch policies.
variable "repository_initialized" {
  description = <<-EOT
    Whether the repository has been initialized with a "main" branch.

    Set this to false only during initial repository bootstrap. After the first
    main branch has been pushed, run Terraform again with the default value of
    true to enable branch protection.
    If this is true when you want to push your first main branch, you will get
    an error because the ruleset will prevent you from pushing to main.
    If this is true when there is no main branch, you will get an error.
  EOT

  type    = bool
  default = true
}
