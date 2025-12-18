#!/bin/bash
set -e

echo "========================================"
echo "Step 1: Deploying Backend Infrastructure"
echo "========================================"

cd backend-setup

# Initialize and apply backend-setup
terraform init
terraform apply -auto-approve

# Capture outputs
BUCKET_NAME=$(terraform output -raw s3_bucket_name)
DYNAMODB_TABLE=$(terraform output -raw dynamodb_table_name)
REGION=$(terraform output -raw aws_region 2>/dev/null || echo "eu-west-1")

echo ""
echo "Backend Infrastructure Created:"
echo "  S3 Bucket: $BUCKET_NAME"
echo "  DynamoDB Table: $DYNAMODB_TABLE"
echo "  Region: $REGION"

# Generate backend configuration file
cd ../main-infra
cat > backend.tfbackend <<EOF
bucket         = "$BUCKET_NAME"
key            = "dev/terraform.tfstate"
region         = "$REGION"
dynamodb_table = "$DYNAMODB_TABLE"
encrypt        = true
EOF

echo ""
echo "========================================"
echo "Backend configuration file created: main-infra/backend.tfbackend"
echo "========================================"

echo ""
echo "========================================"
echo "Step 2: Deploying Main Infrastructure"
echo "========================================"

# Check if terraform.tfvars exists
if [ ! -f "terraform.tfvars" ]; then
    echo ""
    echo "ERROR: terraform.tfvars not found!"
    echo "Please create it from terraform.tfvars.example:"
    echo "  cp terraform.tfvars.example terraform.tfvars"
    echo "  # Edit terraform.tfvars with your values"
    exit 1
fi

# Initialize with backend configuration
terraform init -backend-config=backend.tfbackend -reconfigure

echo ""
echo "Backend initialized successfully!"
echo ""
echo "Next steps:"
echo "  1. Review the plan: terraform plan"
echo "  2. Deploy infrastructure: terraform apply"
echo ""

echo "========================================"
terraform plan
echo "========================================"
terraform apply -auto-approve
