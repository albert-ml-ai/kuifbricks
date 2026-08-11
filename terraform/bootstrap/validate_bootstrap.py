"""
Validate that the kuifbricks bootstrap process completed successfully
before CI/CD is enabled.

Run from the repository root:

    python terraform/bootstrap/validate_bootstrap.py

This script is intentionally read-only. It validates the environment but
does not create, modify, or delete Azure, GitHub, Git, or Terraform resources.

- az account show & gh auth status work
- var ENABLE_CICD is false or doesn't exist (defaults to false for .github/workflows)
- main exists remotely
- Azure OIDC federated credentials exist
- Required GitHub variables are non-empty
- Terraform backend access works
- Working tree is clean before enabling CI/CD
- remote state container exists
"""

from __future__ import annotations

import json
import subprocess
import sys
from pathlib import Path
import shutil
import os

REPO_ROOT = Path(__file__).resolve().parents[2]

REQUIRED_GITHUB_VARIABLES = [
    "AZURE_CLIENT_ID",
    "AZURE_TENANT_ID",
    "AZURE_SUBSCRIPTION_ID",
]

EXPECTED_GITHUB_OIDC_ISSUER = "https://token.actions.githubusercontent.com"


def run(
    command: list[str],
    *,
    cwd: Path = REPO_ROOT,
    check: bool = True,
) -> subprocess.CompletedProcess[str]:
    """Run a command and capture its output."""

    executable = shutil.which(command[0])

    # Some Windows CLIs, such as Azure CLI, are installed as .cmd wrappers.
    if os.name == "nt":
        executable = shutil.which(f"{command[0]}.exe")
        executable = executable or shutil.which(f"{command[0]}.cmd")
    else:
        executable = shutil.which(command[0])

    if executable is None:
        raise RuntimeError(
            f"Required command '{command[0]}' was not found on PATH."
        )

    return subprocess.run(
        [executable, *command[1:]],
        cwd=cwd,
        text=True,
        capture_output=True,
        check=check,
        shell=False,
    )


def pass_check(message: str) -> None:
    print(f"[PASS] {message}")


def fail_check(message: str, details: str | None = None) -> None:
    print(f"[FAIL] {message}")

    if details:
        for line in details.strip().splitlines():
            print(f"       {line}")


def get_github_variable(name: str) -> str | None:
    """Return a repository-level GitHub variable, or None if it does not exist."""
    result = run(
        ["gh", "variable", "get", name],
        check=False,
    )

    if result.returncode != 0:
        return None

    return result.stdout.strip()


def validate_azure_login() -> bool:
    result = run(
        ["az", "account", "show", "--output", "json"],
        check=False,
    )

    if result.returncode != 0:
        fail_check("Azure CLI authentication", result.stderr)
        return False

    account = json.loads(result.stdout)

    pass_check(
        f"Azure CLI authenticated: "
        f"{account.get('name')} ({account.get('id')})"
    )

    return True


def validate_github_login() -> bool:
    result = run(
        ["gh", "auth", "status"],
        check=False,
    )

    if result.returncode != 0:
        fail_check("GitHub CLI authentication", result.stderr)
        return False

    pass_check("GitHub CLI authenticated")
    return True


def validate_enable_cicd() -> bool:
    value = get_github_variable("ENABLE_CICD")

    if value is None:
        pass_check("ENABLE_CICD does not exist and therefore defaults to disabled")
        return True

    if value.lower() == "false":
        pass_check("ENABLE_CICD is false")
        return True

    fail_check(
        "ENABLE_CICD must be false or absent before bootstrap validation",
        f"Current value: {value}",
    )
    return False


def validate_required_github_variables() -> bool:
    success = True

    for name in REQUIRED_GITHUB_VARIABLES:
        value = get_github_variable(name)

        if value:
            pass_check(f"GitHub repository variable {name} is configured")
        else:
            fail_check(f"GitHub repository variable {name} is missing or empty")
            success = False

    return success


def validate_remote_main_branch() -> bool:
    result = run(
        [
            "git",
            "ls-remote",
            "--exit-code",
            "--heads",
            "origin",
            "refs/heads/main",
        ],
        check=False,
    )

    if result.returncode != 0:
        fail_check(
            "Remote main branch exists",
            "Could not find refs/heads/main on origin.",
        )
        return False

    pass_check("Remote main branch exists")
    return True


def validate_working_tree_clean() -> bool:
    result = run(
        ["git", "status", "--porcelain"],
        check=False,
    )

    if result.returncode != 0:
        fail_check("Git working tree check", result.stderr)
        return False

    if result.stdout.strip():
        fail_check(
            "Git working tree must be clean before enabling CI/CD",
            result.stdout,
        )
        return False

    pass_check("Git working tree is clean")
    return True


def validate_oidc_federation() -> bool:
    client_id = get_github_variable("AZURE_CLIENT_ID")

    if not client_id:
        fail_check(
            "Azure OIDC federated credential",
            "AZURE_CLIENT_ID is unavailable.",
        )
        return False

    result = run(
        [
            "az",
            "ad",
            "app",
            "federated-credential",
            "list",
            "--id",
            client_id,
            "--output",
            "json",
        ],
        check=False,
    )

    if result.returncode != 0:
        fail_check(
            "Azure OIDC federated credential",
            result.stderr,
        )
        return False

    credentials = json.loads(result.stdout)

    repo_result = run(
        [
            "gh",
            "repo",
            "view",
            "--json",
            "nameWithOwner",
            "--jq",
            ".nameWithOwner",
        ],
        check=False,
    )

    if repo_result.returncode != 0:
        fail_check("Determine GitHub repository", repo_result.stderr)
        return False

    repository = repo_result.stdout.strip()
    expected_subject_prefix = f"repo:{repository}:"

    matching_credentials = [
        credential
        for credential in credentials
        if credential.get("issuer", "").rstrip("/")
        == EXPECTED_GITHUB_OIDC_ISSUER
        and credential.get("subject", "").startswith(expected_subject_prefix)
        and "api://AzureADTokenExchange"
        in credential.get("audiences", [])
    ]

    if not matching_credentials:
        fail_check(
            "Azure OIDC federated credential",
            (
                "No credential found for GitHub Actions with:\n"
                f"issuer: {EXPECTED_GITHUB_OIDC_ISSUER}\n"
                f"subject prefix: {expected_subject_prefix}"
            ),
        )
        return False

    pass_check(
        f"Azure OIDC federation configured for {repository}"
    )
    return True


def get_bootstrap_output(name: str) -> str | None:
    bootstrap_dir = (
        REPO_ROOT
        / "terraform"
        / "bootstrap"
        / "1_terraform_state"
    )

    result = run(
        [
            "terraform",
            f"-chdir={bootstrap_dir}",
            "output",
            "-raw",
            name,
        ],
        check=False,
    )

    if result.returncode != 0:
        return None

    return result.stdout.strip()


def validate_remote_state_container() -> bool:
    storage_account = get_bootstrap_output("storage_account_name")
    container = get_bootstrap_output("container_name")

    if not storage_account or not container:
        fail_check(
            "Terraform remote state container",
            (
                "Could not read storage_account_name and container_name "
                "from terraform/bootstrap/1_terraform_state outputs."
            ),
        )
        return False

    result = run(
        [
            "az",
            "storage",
            "container",
            "show",
            "--account-name",
            storage_account,
            "--name",
            container,
            "--auth-mode",
            "login",
            "--output",
            "none",
        ],
        check=False,
    )

    if result.returncode != 0:
        fail_check(
            "Terraform remote state container exists and is accessible",
            result.stderr,
        )
        return False

    pass_check(
        f"Terraform state container exists and is accessible: "
        f"{storage_account}/{container}"
    )

    return True


def validate_terraform_backend_access() -> bool:
    github_dir = REPO_ROOT / "terraform" / "github"

    result = run(
        [
            "terraform",
            f"-chdir={github_dir}",
            "state",
            "pull",
        ],
        check=False,
    )

    if result.returncode != 0:
        fail_check(
            "Terraform remote backend access",
            result.stderr,
        )
        return False

    try:
        state = json.loads(result.stdout)
    except json.JSONDecodeError:
        fail_check(
            "Terraform remote backend access",
            "terraform state pull did not return valid Terraform state.",
        )
        return False

    if "version" not in state:
        fail_check(
            "Terraform remote backend access",
            "Remote state was returned but does not look like Terraform state.",
        )
        return False

    pass_check("Terraform GitHub remote state is accessible")
    return True


def main() -> int:
    print()
    print("kuifbricks bootstrap validation")
    print("=" * 32)
    print()

    checks = [
        validate_azure_login,
        validate_github_login,
        validate_enable_cicd,
        validate_required_github_variables,
        validate_remote_main_branch,
        validate_oidc_federation,
        validate_remote_state_container,
        validate_terraform_backend_access,
        validate_working_tree_clean,
    ]

    results = []

    for check in checks:
        try:
            results.append(check())
        except RuntimeError as error:
            fail_check(str(error))
            results.append(False)
        except (json.JSONDecodeError, subprocess.SubprocessError) as error:
            fail_check(
                f"Unexpected validation error in {check.__name__}",
                str(error),
            )
            results.append(False)

    passed = sum(results)
    total = len(results)

    print()
    print("=" * 32)

    if all(results):
        print(f"[SUCCESS] Bootstrap validation passed ({passed}/{total})")
        print("CI/CD can now be enabled.")
        return 0

    print(f"[FAILED] Bootstrap validation failed ({passed}/{total} passed)")
    print("Fix the failed checks before enabling CI/CD.")
    return 1


if __name__ == "__main__":
    sys.exit(main())