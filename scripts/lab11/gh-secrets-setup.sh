#!/bin/bash
set -e

# One-time, local-only:
# - creates a user-assigned managed identity that GitHub Actions logs in as (OIDC, no stored secret)
# - pushes its identifiers to GitHub Actions secrets.
# A managed identity is used instead of an Entra app registration because university tenants
# (e.g. UTS) block students from registering applications, but allow resources in their own subscription.

# Prevents Git Bash on Windows from rewriting --scope "/subscriptions/..." into a local file path.
export MSYS_NO_PATHCONV=1

IDENTITY_NAME="lab11-github-oidc"
# Kept outside lab11-rg so cleanup.sh does not delete the CI login identity.
IDENTITY_RG="${IDENTITY_RG:-lab11-identity-rg}"
LOCATION="${LOCATION:-australiaeast}"

echo "=== Lab 11 GitHub Secrets Setup ==="

if ! az account show >/dev/null 2>&1; then
    az login
fi
echo "Logged in to Azure."

if ! gh auth status >/dev/null 2>&1; then
    gh auth login
    echo "Logged in to GitHub."
fi

REPO_URL=$(git config --get remote.origin.url)
REPO_SLUG=$(echo "$REPO_URL" | sed -E 's#(git@github.com:|https://github.com/)##; s#\.git$##')
BRANCH=$(git rev-parse --abbrev-ref HEAD)

SUBSCRIPTION_ID=$(az account show --query id -o tsv)
TENANT_ID=$(az account show --query tenantId -o tsv)

if [ -z "$SUBSCRIPTION_ID" ]; then
    echo "No active subscription found on the current Azure login."
    echo "Run 'az account list --output table' to see available subscriptions, then 'az account set --subscription <id>' and re-run this script."
    exit 1
fi

echo "Registering Microsoft.ManagedIdentity provider (skips if already registered)..."
az provider register --namespace Microsoft.ManagedIdentity --wait

az group create --name "$IDENTITY_RG" --location "$LOCATION" --output none

if ! az identity show --name "$IDENTITY_NAME" --resource-group "$IDENTITY_RG" >/dev/null 2>&1; then
    echo "Creating managed identity '$IDENTITY_NAME'..."
    az identity create --name "$IDENTITY_NAME" --resource-group "$IDENTITY_RG" --location "$LOCATION" --output none
else
    echo "Found existing managed identity '$IDENTITY_NAME'."
fi

CLIENT_ID=$(az identity show --name "$IDENTITY_NAME" --resource-group "$IDENTITY_RG" --query clientId -o tsv)
PRINCIPAL_ID=$(az identity show --name "$IDENTITY_NAME" --resource-group "$IDENTITY_RG" --query principalId -o tsv)
echo "Fetched subscription ID, tenant ID, and client ID from Azure."

# GitHub may send either the classic name-based subject or the newer immutable ID-based one,
# so trust both. Re-synced on every run in case the repo or owner was renamed.
OWNER_NAME=$(echo "$REPO_SLUG" | cut -d/ -f1)
REPO_NAME=$(echo "$REPO_SLUG" | cut -d/ -f2)
OWNER_ID=$(gh api "repos/${REPO_SLUG}" --jq '.owner.id')
REPO_ID=$(gh api "repos/${REPO_SLUG}" --jq '.id')
SUBJECT_CLASSIC="repo:${REPO_SLUG}:ref:refs/heads/${BRANCH}"
SUBJECT_IMMUTABLE="repo:${OWNER_NAME}@${OWNER_ID}/${REPO_NAME}@${REPO_ID}:ref:refs/heads/${BRANCH}"

sync_federated_credential() {
    local cred_name="$1"
    local subject="$2"
    local action="create"
    if az identity federated-credential show --name "$cred_name" --identity-name "$IDENTITY_NAME" --resource-group "$IDENTITY_RG" >/dev/null 2>&1; then
        action="update"
    fi
    az identity federated-credential "$action" \
      --name "$cred_name" \
      --identity-name "$IDENTITY_NAME" \
      --resource-group "$IDENTITY_RG" \
      --issuer "https://token.actions.githubusercontent.com" \
      --subject "$subject" \
      --audiences "api://AzureADTokenExchange" \
      --output none
    echo "Synced federated credential '$cred_name' to subject '$subject'."
}

sync_federated_credential "lab11-github-actions" "$SUBJECT_CLASSIC"
sync_federated_credential "lab11-github-actions-immutable" "$SUBJECT_IMMUTABLE"

# Object ID + principal type avoids directory (Graph) lookups, which restricted tenants block.
grant_role() {
    local role="$1"
    local existing
    existing=$(az role assignment list \
      --scope "/subscriptions/$SUBSCRIPTION_ID" \
      --role "$role" \
      --fill-principal-name false \
      --query "[?principalId=='$PRINCIPAL_ID'].id" -o tsv 2>/dev/null || true)

    if [ -z "$existing" ]; then
        az role assignment create \
          --assignee-object-id "$PRINCIPAL_ID" \
          --assignee-principal-type ServicePrincipal \
          --role "$role" \
          --scope "/subscriptions/$SUBSCRIPTION_ID" \
          --output none
        echo "Granted $role role."
    else
        echo "$role role already assigned."
    fi
}

grant_role "Contributor"
# Contributor alone excludes roleAssignments/write, which deploy-azure.sh needs for the AcrPull auto-grant.
grant_role "User Access Administrator"

gh secret set AZURE_SUBSCRIPTION_ID --body "$SUBSCRIPTION_ID"
gh secret set AZURE_TENANT_ID --body "$TENANT_ID"
gh secret set AZURE_CLIENT_ID --body "$CLIENT_ID"
echo "Pushed AZURE_SUBSCRIPTION_ID, AZURE_TENANT_ID, and AZURE_CLIENT_ID to GitHub Actions secrets."

echo "=== GitHub Secrets Setup Complete ==="
