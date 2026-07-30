output "repository_full_name" {
  description = "Full GitHub repository name."
  value       = github_repository.kuifbricks.full_name
}

output "repository_git_clone_url" {
  description = "Git clone URL of the repository."
  value       = github_repository.kuifbricks.git_clone_url
}

output "repository_html_url" {
  description = "Web URL of the repository."
  value       = github_repository.kuifbricks.html_url
}

output "repository_ssh_clone_url" {
  description = "SSH clone URL of the repository."
  value       = github_repository.kuifbricks.ssh_clone_url
}
