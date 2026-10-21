#!/bin/bash
set -e

# Creates the ACR and builds/pushes all 3 service images.

echo "=== Lab 11 Image Build ==="

RESOURCE_GROUP="${RESOURCE_GROUP:-lab11-rg}"
IMAGE_TAG="latest"

# Step 1: Read the registry name from resource group tags
REGISTRY_NAME=$(az group show --name "$RESOURCE_GROUP" --query "tags.registryName" -o tsv)

if [[ -z "$REGISTRY_NAME" ]]; then
  echo "Resource group $RESOURCE_GROUP is missing deployment tags. Run scripts/lab11/env-setup.sh first." >&2
  exit 1
fi

# Step 2: Create Azure Container Registry (skipped if a previous run already created it)
if az acr show --name "$REGISTRY_NAME" --resource-group "$RESOURCE_GROUP" >/dev/null 2>&1; then
  echo "Azure Container Registry $REGISTRY_NAME already exists."
else
  echo "Creating Azure Container Registry..."
  az acr create \
    --resource-group "$RESOURCE_GROUP" \
    --name "$REGISTRY_NAME" \
    --sku Basic
fi

# getent is missing in Git Bash on Windows, so fall back to nslookup there.
resolves() {
  if command -v getent >/dev/null 2>&1; then
    getent hosts "$1" >/dev/null 2>&1
  else
    nslookup "$1" >/dev/null 2>&1
  fi
}

# Step 2b: Wait for the registry's DNS name to propagate before building.
# A fresh ACR can report "created" before *.azurecr.io resolves, causing
# the first push to fail with "no such host".
LOGIN_SERVER="${REGISTRY_NAME}.azurecr.io"
echo "Waiting for $LOGIN_SERVER to resolve..."
for i in $(seq 1 24); do
  if resolves "$LOGIN_SERVER"; then
    echo "$LOGIN_SERVER is resolvable."
    break
  fi
  if [[ "$i" -eq 24 ]]; then
    echo "Timed out waiting for $LOGIN_SERVER to resolve." >&2
    exit 1
  fi
  sleep 5
done

# Step 3: Build locally with Docker and push all 3 container images.
# `az acr build` is not used because ACR Tasks are blocked on free/student subscriptions.
az acr login --name "$REGISTRY_NAME"

echo "Building and pushing database-service image..."
docker build -t "${LOGIN_SERVER}/database-service:${IMAGE_TAG}" ./database-service
docker push "${LOGIN_SERVER}/database-service:${IMAGE_TAG}"

echo "Building and pushing enrolment-service image..."
docker build -t "${LOGIN_SERVER}/enrolment-service:${IMAGE_TAG}" -f enrolment-service/Dockerfile .
docker push "${LOGIN_SERVER}/enrolment-service:${IMAGE_TAG}"

echo "Building and pushing frontend-service image..."
docker build -t "${LOGIN_SERVER}/frontend-service:${IMAGE_TAG}" ./frontend-service
docker push "${LOGIN_SERVER}/frontend-service:${IMAGE_TAG}"

echo "=== Image Build Complete ==="
