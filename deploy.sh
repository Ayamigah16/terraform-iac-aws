#!/bin/bash

# Fail-safe scripting
set -euo pipefail  # Exit on error, undefined vars, pipe failures
IFS=$'\n\t'        # Set safer internal field separator

# Configuration
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly LOG_FILE="${SCRIPT_DIR}/deploy.log"
readonly BACKEND_DIR="${SCRIPT_DIR}/backend-setup"
readonly MAIN_INFRA_DIR="${SCRIPT_DIR}/main-infra"

# Logging functions
log_info() {
    local msg="[$(date +'%Y-%m-%d %H:%M:%S')] [INFO] $*"
    echo "$msg" | tee -a "$LOG_FILE"
}

log_success() {
    local msg="[$(date +'%Y-%m-%d %H:%M:%S')] [SUCCESS] $*"
    echo -e "\033[0;32m${msg}\033[0m" | tee -a "$LOG_FILE"
}

log_error() {
    local msg="[$(date +'%Y-%m-%d %H:%M:%S')] [ERROR] $*"
    echo -e "\033[0;31m${msg}\033[0m" | tee -a "$LOG_FILE" >&2
}

log_warning() {
    local msg="[$(date +'%Y-%m-%d %H:%M:%S')] [WARNING] $*"
    echo -e "\033[0;33m${msg}\033[0m" | tee -a "$LOG_FILE"
}

# Cleanup function on error
cleanup_on_error() {
    local exit_code=$?
    if [ $exit_code -ne 0 ]; then
        log_error "Deployment failed with exit code: $exit_code"
        log_info "Check the log file for details: $LOG_FILE"
    fi
    exit $exit_code
}

# Set trap for cleanup
trap cleanup_on_error EXIT

# Validate prerequisites
validate_prerequisites() {
    log_info "Validating prerequisites..."
    
    # Check if terraform is installed
    if ! command -v terraform &> /dev/null; then
        log_error "Terraform is not installed. Please install Terraform first."
        exit 1
    fi
    
    # Check if AWS CLI is configured
    if ! aws sts get-caller-identity &> /dev/null; then
        log_error "AWS CLI is not configured or credentials are invalid."
        log_error "Run: aws configure"
        exit 1
    fi
    
    # Check if required directories exist
    if [ ! -d "$BACKEND_DIR" ]; then
        log_error "Backend directory not found: $BACKEND_DIR"
        exit 1
    fi
    
    if [ ! -d "$MAIN_INFRA_DIR" ]; then
        log_error "Main infrastructure directory not found: $MAIN_INFRA_DIR"
        exit 1
    fi
    
    log_success "Prerequisites validated successfully"
}

# Deploy backend infrastructure
deploy_backend() {
    log_info "========================================"
    log_info "Step 1: Deploying Backend Infrastructure"
    log_info "========================================"
    
    cd "$BACKEND_DIR" || {
        log_error "Failed to change directory to: $BACKEND_DIR"
        exit 1
    }
    
    log_info "Initializing Terraform for backend..."
    terraform init >> "$LOG_FILE" 2>&1 || {
        log_error "Terraform init failed for backend"
        exit 1
    }
    
    log_info "Applying backend configuration..."
    terraform apply -auto-approve >> "$LOG_FILE" 2>&1 || {
        log_error "Terraform apply failed for backend"
        exit 1
    }
    
    log_success "Backend infrastructure deployed successfully"
}

# Capture backend outputs
capture_backend_outputs() {
    log_info "Capturing backend outputs..."
    
    cd "$BACKEND_DIR" || exit 1
    
    BUCKET_NAME=$(terraform output -raw s3_bucket_name 2>/dev/null) || {
        log_error "Failed to get S3 bucket name"
        exit 1
    }
    
    DYNAMODB_TABLE=$(terraform output -raw dynamodb_table_name 2>/dev/null) || {
        log_error "Failed to get DynamoDB table name"
        exit 1
    }
    
    REGION=$(terraform output -raw aws_region 2>/dev/null || echo "eu-west-1")
    
    log_info "Backend Infrastructure Details:"
    log_info "  S3 Bucket: $BUCKET_NAME"
    log_info "  DynamoDB Table: $DYNAMODB_TABLE"
    log_info "  Region: $REGION"
    
    # Validate outputs are not empty
    if [ -z "$BUCKET_NAME" ] || [ -z "$DYNAMODB_TABLE" ]; then
        log_error "Backend outputs are empty or invalid"
        exit 1
    fi
    
    log_success "Backend outputs captured successfully"
}

# Generate backend configuration
generate_backend_config() {
    log_info "Generating backend configuration file..."
    
    cd "$MAIN_INFRA_DIR" || exit 1
    
    cat > backend.tfbackend <<EOF
bucket         = "$BUCKET_NAME"
key            = "dev/terraform.tfstate"
region         = "$REGION"
dynamodb_table = "$DYNAMODB_TABLE"
encrypt        = true
EOF

    if [ ! -f "backend.tfbackend" ]; then
        log_error "Failed to create backend.tfbackend file"
        exit 1
    fi
    
    log_success "Backend configuration file created: main-infra/backend.tfbackend"
}

# Deploy main infrastructure
deploy_main_infrastructure() {
    log_info "========================================"
    log_info "Step 2: Deploying Main Infrastructure"
    log_info "========================================"
    
    cd "$MAIN_INFRA_DIR" || exit 1
    
    # Check if terraform.tfvars exists
    if [ ! -f "terraform.tfvars" ]; then
        log_error "terraform.tfvars not found!"
        log_info "Please create it from terraform.tfvars.example:"
        log_info "  cp terraform.tfvars.example terraform.tfvars"
        log_info "  # Edit terraform.tfvars with your values"
        exit 1
    fi
    
    log_info "Initializing Terraform with backend configuration..."
    terraform init -backend-config=backend.tfbackend -reconfigure >> "$LOG_FILE" 2>&1 || {
        log_error "Terraform init failed for main infrastructure"
        exit 1
    }
    
    log_success "Backend initialized successfully"
    
    log_info "Running terraform plan..."
    terraform plan -out=tfplan >> "$LOG_FILE" 2>&1 || {
        log_error "Terraform plan failed"
        exit 1
    }
    
    log_info "Applying infrastructure..."
    terraform apply tfplan >> "$LOG_FILE" 2>&1 || {
        log_error "Terraform apply failed"
        rm -f tfplan
        exit 1
    }
    
    # Cleanup plan file
    rm -f tfplan
    
    log_success "Main infrastructure deployed successfully"
}

# Main execution
main() {
    log_info "Starting deployment process..."
    log_info "Log file: $LOG_FILE"
    
    validate_prerequisites
    deploy_backend
    capture_backend_outputs
    generate_backend_config
    deploy_main_infrastructure
    
    log_success "========================================"
    log_success "Deployment completed successfully!"
    log_success "========================================"
    log_info "Next steps:"
    log_info "  - View outputs: cd main-infra && terraform output"
    log_info "  - Check resources in AWS Console"
    log_info "  - Review logs: cat $LOG_FILE"
}

# Run main function
main
