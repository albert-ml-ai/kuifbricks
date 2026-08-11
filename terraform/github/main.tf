/*
  This Terraform configuration manages the GitHub repository settings for
  kuifbricks. Why: managing repository settings through Terraform makes it
  explicit, version-controlled and reproducible.
*/

/* 1. Init GitHub repository
  Vulnerability alerts and Dependabot security updates are enabled because
  this repository will contain dependencies such as Terraform providers,
  Python packages and GitHub Actions.
  GitHub vulnerability alerts identify dependencies with known security
  vulnerabilities. Dependabot security updates can then open pull requests
  containing an available security fix.
*/

resource "github_repository" "kuifbricks" {
  name        = var.repository_name
  description = var.repository_description
  visibility  = "public"

  has_discussions = false
  has_issues      = true
  has_projects    = false
  has_wiki        = false

  allow_auto_merge       = true
  allow_merge_commit     = false
  allow_rebase_merge     = false
  allow_squash_merge     = true
  delete_branch_on_merge = true

  squash_merge_commit_message = "PR_BODY"
  squash_merge_commit_title   = "PR_TITLE"

  topics = var.repository_topics

  lifecycle {
    prevent_destroy = true
  }
}

resource "github_repository_vulnerability_alerts" "kuifbricks" {
  repository = github_repository.kuifbricks.name
}

resource "github_repository_dependabot_security_updates" "kuifbricks" {
  repository = github_repository.kuifbricks.name
  enabled    = true
  depends_on = [
    github_repository_vulnerability_alerts.kuifbricks
  ]
}

/* 2. Branch policies
  Single long-lived branch called 'main', becomes the default branch.
  Requirements:
  - repo was created above with terraform apply -var="repository_initialized=false"

  The ruleset is conditionally omitted during initial repository bootstrap,
  with `terraform apply -var="repository_initialized=false"`,
  because the repository must first receive its initial main branch. After
  that first push, the ruleset is enabled and all future changes to main must
  be made through a pull request.

  Branch deletion and force pushes are blocked to preserve the long-lived
  branch and its history.
*/
resource "github_branch_default" "main" {
  count = var.repository_initialized ? 1 : 0

  repository = github_repository.kuifbricks.name
  branch     = "main"
}

resource "github_repository_ruleset" "main" {
  count = var.repository_initialized ? 1 : 0

  name        = "Protect main"
  repository  = github_repository.kuifbricks.name
  target      = "branch"
  enforcement = "active"

  conditions {
    ref_name {
      include = ["refs/heads/main"]
      exclude = []
    }
  }

  rules {
    deletion         = true
    non_fast_forward = true

    pull_request {
      required_approving_review_count = 0
    }
  }

  lifecycle {
    prevent_destroy = true
  }
}