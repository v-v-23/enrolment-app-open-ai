#!/bin/bash
set -e

# Creates the resource group and tags it with generated deployment names.

RESOURCE_GROUP="${RESOURCE_GROUP:-lab11-rg}"
LOCATION="${LOCATION:-australiaeast}"

echo "=== Lab 11 Environment Setup ==="

echo "Registering required resource providers (skips if already registered)..."
az provider register --namespace Microsoft.App --wait
az provider register --namespace Microsoft.OperationalInsights --wait
az provider register --namespace Microsoft.ContainerRegistry --wait

EXISTING_REGISTRY=$(az group show --name "$RESOURCE_GROUP" --query "tags.registryName" -o tsv 2>/dev/null || true)

if [[ -n "$EXISTING_REGISTRY" ]]; then
  echo "Resource group $RESOURCE_GROUP is already configured — reusing existing names."
  az group show --name "$RESOURCE_GROUP" --query tags -o table
  exit 0
fi

REGISTRY_NAME="lab11registry${RANDOM}"
ENV_NAME="lab11-env-${RANDOM}"
FRONTEND_APP_NAME="frontend-app-${RANDOM}"
ENROLMENT_APP_NAME="enrolment-app-${RANDOM}"
DB_APP_NAME="database-app-${RANDOM}"

echo "Creating resource group..."
az group create --name "$RESOURCE_GROUP" --location "$LOCATION"

echo "Tagging resource group with deployment names..."
az group update \
  --name "$RESOURCE_GROUP" \
  --tags registryName="$REGISTRY_NAME" envName="$ENV_NAME" \
    frontendAppName="$FRONTEND_APP_NAME" enrolmentAppName="$ENROLMENT_APP_NAME" dbAppName="$DB_APP_NAME" \
    location="$LOCATION"

echo "=== Environment Setup Complete ==="
az group show --name "$RESOURCE_GROUP" --query tags -o table
