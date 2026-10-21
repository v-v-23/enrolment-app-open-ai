#!/bin/bash
set -e

# Deletes the Lab 11 resource group and everything inside it.

RESOURCE_GROUP="${RESOURCE_GROUP:-lab11-rg}"

echo "=== Lab 11 Cleanup ==="

REGISTRY_NAME=$(az group show --name "$RESOURCE_GROUP" --query "tags.registryName" -o tsv 2>/dev/null || true)
ENV_NAME=$(az group show --name "$RESOURCE_GROUP" --query "tags.envName" -o tsv 2>/dev/null || true)
FRONTEND_APP_NAME=$(az group show --name "$RESOURCE_GROUP" --query "tags.frontendAppName" -o tsv 2>/dev/null || true)
ENROLMENT_APP_NAME=$(az group show --name "$RESOURCE_GROUP" --query "tags.enrolmentAppName" -o tsv 2>/dev/null || true)
DB_APP_NAME=$(az group show --name "$RESOURCE_GROUP" --query "tags.dbAppName" -o tsv 2>/dev/null || true)

if [[ -z "$REGISTRY_NAME" ]]; then
  echo "Resource group $RESOURCE_GROUP not found or has no deployment tags — nothing to clean up." >&2
  exit 0
fi

echo "This will permanently delete resource group: $RESOURCE_GROUP"
echo "  Registry: $REGISTRY_NAME"
echo "  Environment: $ENV_NAME"
echo "  Frontend App: $FRONTEND_APP_NAME"
echo "  Enrolment App: $ENROLMENT_APP_NAME"
echo "  Database App: $DB_APP_NAME"

if [[ -z "${CI:-}" ]]; then
  read -p "Type the resource group name to confirm: " CONFIRM
  if [[ "$CONFIRM" != "$RESOURCE_GROUP" ]]; then
    echo "Confirmation did not match. Aborting." >&2
    exit 1
  fi
fi

az group delete --name "$RESOURCE_GROUP" --yes --no-wait

echo "=== Deletion started ==="
echo "Resource group $RESOURCE_GROUP is being deleted in the background."
echo "Check progress with: az group show --name $RESOURCE_GROUP"