#!/bin/bash
set -e

echo "========================================"
echo "Destroying Infrastructure"
echo "========================================"

# Confirm destruction
read -p "Are you sure you want to destroy ALL infrastructure? (yes/no): " confirm
if [ "$confirm" != "yes" ]; then
    echo "Destruction cancelled."
    exit 0
fi

echo ""
echo "Step 1: Destroying Main Infrastructure..."
cd main-infra
if [ -f "backend.tfbackend" ]; then
    terraform init -backend-config=backend.tfbackend
fi
terraform destroy -auto-approve

echo ""
echo "Step 2: Destroying Backend Infrastructure..."
cd ../backend-setup
terraform destroy -auto-approve

echo ""
echo "========================================"
echo "All infrastructure destroyed successfully!"
echo "========================================"
