#!/bin/bash
set -e

# Creates the Container Apps environment (run build-images.sh first, deploy-azure.sh after).
# Kept separate from deploy-azure.sh because the first creation is slow and CI refreshes
# its Azure login in between.

echo "=== Lab 11 Container Apps Environment ==="

RESOURCE_GROUP="${RESOURCE_GROUP:-lab11-rg}"

ENV_NAME=$(az group show --name "$RESOURCE_GROUP" --query "tags.envName" -o tsv)
LOCATION=$(az group show --name "$RESOURCE_GROUP" --query "tags.location" -o tsv)

if [[ -z "$ENV_NAME" || -z "$LOCATION" ]]; then
  echo "Resource group $RESOURCE_GROUP is missing deployment tags. Run scripts/lab11/env-setup.sh first." >&2
  exit 1
fi

# Safe to re-run: skip creation if an earlier run already made the environment.
if az containerapp env show --name "$ENV_NAME" --resource-group "$RESOURCE_GROUP" >/dev/null 2>&1; then
  echo "Container Apps environment $ENV_NAME already exists."
else
  echo "Creating Container Apps environment (the first run can take 15-20 minutes)..."
  az containerapp env create \
    --name "$ENV_NAME" \
    --resource-group "$RESOURCE_GROUP" \
    --location "$LOCATION" \
    --environment-mode WorkloadProfiles \
    --output none
fi

echo "=== Container Apps Environment Ready ==="
