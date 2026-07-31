# Kuifbricks
This Azure Databricks monorepo showcases best practices for building and operating data and ML platforms on Azure Databricks.

It is designed to be modular and extensible, so you can use it as a starting point for your own projects.

## Setup overall

**Set up your infra using bootstraps**
1. Bootstrap terraform create blob storage for tfstate files remote. This is the only tfstate kept locally. 
2. Terraform Apply terraform/github in bootstrap mode with -var="repository_initialized=false" 
3. Git init and commit existing files as main branch. Existing files include .github with triggers on pipelines. But the default var.ENABLE_CICD is false. 
4. Bootstrap Create azure sp for github actions. 
5. Set Azure GitHub Actions variables. 
6. run bootstrap/bootstrap_validate.py. Checks if var.ENABLE_CICD is false, if other vars are set, whether az login and gh auth login work.

**Apply all terraform directories for the first time in the correct order**
7. Terraform Apply terraform/github in normal mode, which includes branch policies and set main default, and it sets ENABLE_CICD to true.
8. Terraform Apply terraform/azure which includes azure storage, databricks workspaces.
9. Terraform Apply terraform/entra which includes entra ids: two test users, additional sps.
10. Terraform Apply terraform/databricks_account which includes metastore
11. Terraform Apply terraform/databricks_workspace which includes catalogs, grants, ABAC. 

## Things I did that are not in code

1. install VS Code
1. install terraform from https://developer.hashicorp.com/terraform/install#windows
1. install VS Code extension Hashicorp Terraform
1. install github CLI and authenticate (powershell)
    - winget install --id GitHub.cli
    < close and reopen powerhell >
    - gh auth login
    - choose:
        - GitHub.com
        - HTTPS
        - Login with a web browser
    - gh auth status
    - gh api user --jq ".login"
    - git ls-remote https://github.com/hashicorp/terraform.git HEAD
1. Create Azure account with subscription, set monthly budget with alerts immediately
1. install azure CLI and authenticate (powershell)
    - winget install --exact --id Microsoft.AzureCLI
    < close and reopen powerhell >
    - az version
    - az login
    - az account show --output table
1. Fill out terraform\github\terraform.tfvars, make sure your azure_subscription_id var is correct
    - during terraform apply in next step, westeurope might be unavailable for new azure resources
    - if needed, switch to different region e.g. northeurope in terraform/bootstrap/1_terraform_state/terraform.tfvars
1. Run bootstrap terraform_state to create azure blob storage for remote .tfstate tracking
    - cd terraform/bootstrap/1_terraform_state
    - terraform init
    - terraform plan
    - terraform apply



------- To be updated: -----
1. fill out terraform\github\terraform.tfvars, make sure your github_owner var is correct
1. Terraform Apply terraform/github in bootstrap mode (powershell)
- cd terraform\github
- terraform init
- terraform plan -var="repository_initialized=false"
- terraform apply -var="repository_initialized=false"
1. init the repo with main branch (powershell)
- (cd ../..)
- git init
- git add .
- git commit -m "Initialize repository"
- git branch -M main
- git remote add origin https://github.com/<github_owner>/<repository_name>.git
- git push -u origin main
1. again apply the terraform config as above, but now without the -var flag.

... for Databricks set auto-termination, restrictive cluster policies, and low quotas.

## Terraform/, what belongs where?

### github/
Manage:

GitHub repository settings
Repository rulesets
Branch policies
Required status checks
GitHub environments such as dev, acc, and prd
Environment protection rules
Actions variables
Possibly Actions secrets, but preferably only when securely injected
Repository topics
Dependabot configuration where appropriate

### azure/
Manage Azure Resource Manager resources:
azurerm

Resource groups
Storage accounts
ADLS Gen2 containers
Key Vault
Managed identities
Role assignments
Virtual networks, subnets, private endpoints, and private DNS if included
Log Analytics
Azure Databricks workspace
Azure-side access required by Unity Catalog storage credentials

### entra/
Manage ENTRA ID accounts:
azuread

Assigns SPs (except the terraform SP which is created during bootstrap)
Assigns two test users and one admin user
Databricks auth will use entra roles.

### databricks_account/

Manage account-scoped Databricks resources:

Account groups
Account service principals
Group memberships
Workspace assignments
Metastore
Metastore assignments
Governed tags
Account-level identity and governance settings
Possibly storage credentials and external locations, depending on the exact provider scope and design

### databricks_workspace/

Manage Databricks and Unity Catalog resources available through a workspace context:

Catalogs
Schemas, depending on your chosen ownership boundary
Storage credentials
External locations
Grants
SQL warehouses
Cluster policies
Secret scopes
Workspace settings
Unity Catalog bindings
ABAC policies
Possibly shared job infrastructure that is not deployed through DABs (avoid)

