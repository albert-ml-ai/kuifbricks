# setup

## Things I did that are not in code

1. install VS Code
1. install terraform from https://developer.hashicorp.com/terraform/install#windows
1. install github CLI (powershell)
    - winget install --id GitHub.cli
    - gh auth login
    - choose:
        - GitHub.com
        - HTTPS
        - Login with a web browser
    - gh auth status
    - gh api user --jq ".login"
    - git ls-remote https://github.com/hashicorp/terraform.git HEAD
1. fill out terraform\github\terraform.tfvars, make sure your github_owner var is correct
1. Create the repo without main branch policies (powershell)
- cd terraform\github-
- terraform init-
- terraform plan -var="enable_main_branch_protection=false"
- terraform apply -var="enable_main_branch_protection=false"
1. init the repo with main branch (powershell)
- (cd ../..)
- git init
- git add .
- git commit -m "Initialize repository"
- git branch -M main
- git remote add origin https://github.com/<owner>/<repository>.git
- git push -u origin main

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

