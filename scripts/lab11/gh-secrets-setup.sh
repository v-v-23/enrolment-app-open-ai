#!/bin/bash
set -e

# One-time, local-only (STUDENT-TENANT VARIANT):
# - creates a user-assigned MANAGED IDENTITY (an Azure resource, so no Entra directory
#   permission is needed - unlike 'az ad app create', which student tenants block)
# - adds a GitHub OIDC federated credential to it
# - grants it Contributor + User Access Administrator on the subscription
# - pushes its identifiers to GitHub Actions secrets
# The identity lives in its own resource group so scripts/lab11/cleanup.sh (which deletes
# lab11-rg) does not remove it.

# Prevents Git Bash on Windows from rewriting --scope "/subscriptions/..." into a local file path.
export MSYS_NO_PATHCONV=1

IDENTITY_NAME="lab11-github-oidc"
IDENTITY_RG="${IDENTITY_RG:-lab11-identity-rg}"
LOCATION="${LOCATION:-australiaeast}"
FED_CRED_NAME="lab11-github-actions"

echo "=== Lab 11 GitHub Secrets Setup (managed identity variant) ==="

az login
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

# Resource group for the identity (idempotent)
echo "Ensuring resource group '$IDENTITY_RG' exists..."
az group create --name "$IDENTITY_RG" --location "$LOCATION" --output none

# Managed identity (create if missing)
CLIENT_ID=$(az identity show --name "$IDENTITY_NAME" --resource-group "$IDENTITY_RG" --query clientId -o tsv 2>/dev/null || true)

if [ -z "$CLIENT_ID" ]; then
    echo "No managed identity named '$IDENTITY_NAME' found. Creating it..."
    az identity create --name "$IDENTITY_NAME" --resource-group "$IDENTITY_RG" --location "$LOCATION" --output none
    CLIENT_ID=$(az identity show --name "$IDENTITY_NAME" --resource-group "$IDENTITY_RG" --query clientId -o tsv)
    echo "Created managed identity."
else
    echo "Found existing managed identity '$IDENTITY_NAME'."
fi
PRINCIPAL_ID=$(az identity show --name "$IDENTITY_NAME" --resource-group "$IDENTITY_RG" --query principalId -o tsv)
echo "Fetched subscription ID, tenant ID, and client ID from Azure."

# Re-synced on every run: GitHub's OIDC subject changes if the repo/owner is renamed or transferred.
# Repos created/renamed/transferred after 2026-07-15 use the immutable subject format
# (owner/repo IDs instead of names), so the IDs are fetched live rather than assumed.
OWNER_NAME=$(echo "$REPO_SLUG" | cut -d/ -f1)
REPO_NAME=$(echo "$REPO_SLUG" | cut -d/ -f2)
OWNER_ID=$(gh api "repos/${REPO_SLUG}" --jq '.owner.id')
REPO_ID=$(gh api "repos/${REPO_SLUG}" --jq '.id')
SUBJECT="repo:${OWNER_NAME}@${OWNER_ID}/${REPO_NAME}@${REPO_ID}:ref:refs/heads/${BRANCH}"

EXISTING_FED_CRED=$(az identity federated-credential list --identity-name "$IDENTITY_NAME" --resource-group "$IDENTITY_RG" --query "[?name=='$FED_CRED_NAME'].name" -o tsv 2>/dev/null || true)

if [ -z "$EXISTING_FED_CRED" ]; then
    az identity federated-credential create \
      --name "$FED_CRED_NAME" \
      --identity-name "$IDENTITY_NAME" \
      --resource-group "$IDENTITY_RG" \
      --issuer "https://token.actions.githubusercontent.com" \
      --subject "$SUBJECT" \
      --audiences "api://AzureADTokenExchange" \
      --output none
    echo "Created federated credential with subject '$SUBJECT'."
else
    az identity federated-credential update \
      --name "$FED_CRED_NAME" \
      --identity-name "$IDENTITY_NAME" \
      --resource-group "$IDENTITY_RG" \
      --issuer "https://token.actions.githubusercontent.com" \
      --subject "$SUBJECT" \
      --audiences "api://AzureADTokenExchange" \
      --output none
    echo "Synced federated credential to subject '$SUBJECT'."
fi

SCOPE="/subscriptions/$SUBSCRIPTION_ID"

# Role assignments use the identity's object ID directly (no directory lookup needed).
# Checked on every run: an earlier run may have failed part-way through.
EXISTING_CONTRIBUTOR=$(az role assignment list --scope "$SCOPE" --query "[?principalId=='$PRINCIPAL_ID' && roleDefinitionName=='Contributor'].id | [0]" -o tsv 2>/dev/null || true)

if [ -z "$EXISTING_CONTRIBUTOR" ]; then
    az role assignment create \
      --assignee-object-id "$PRINCIPAL_ID" \
      --assignee-principal-type ServicePrincipal \
      --role Contributor \
      --scope "$SCOPE" \
      --output none
    echo "Granted Contributor role."
else
    echo "Contributor role already assigned."
fi

# Contributor alone isn't enough for the AcrPull auto-grant in deploy-azure.sh.
EXISTING_UAA=$(az role assignment list --scope "$SCOPE" --query "[?principalId=='$PRINCIPAL_ID' && roleDefinitionName=='User Access Administrator'].id | [0]" -o tsv 2>/dev/null || true)

if [ -z "$EXISTING_UAA" ]; then
    az role assignment create \
      --assignee-object-id "$PRINCIPAL_ID" \
      --assignee-principal-type ServicePrincipal \
      --role "User Access Administrator" \
      --scope "$SCOPE" \
      --output none
    echo "Granted User Access Administrator role (needed for AcrPull role assignments in deploy-azure.sh)."
else
    echo "User Access Administrator role already assigned."
fi

gh secret set AZURE_SUBSCRIPTION_ID --body "$SUBSCRIPTION_ID"
gh secret set AZURE_TENANT_ID --body "$TENANT_ID"
gh secret set AZURE_CLIENT_ID --body "$CLIENT_ID"
echo "Pushed AZURE_SUBSCRIPTION_ID, AZURE_TENANT_ID, and AZURE_CLIENT_ID to GitHub Actions secrets."

echo "=== GitHub Secrets Setup Complete ==="