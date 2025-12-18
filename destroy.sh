#!/bin/bash

# Fail-safe scripting
set -euo pipefail  # Exit on error, undefined vars, pipe failures
IFS=$'\n\t'        # Set safer internal field separator

# Configuration
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly LOG_FILE="${SCRIPT_DIR}/destroy.log"
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
        log_error "Destruction failed with exit code: $exit_code"
        log_info "Check the log file for details: $LOG_FILE"
        log_warning "Some resources may still exist. Please check AWS Console."
    fi
    exit $exit_code
}

# Set trap for cleanup
trap cleanup_on_error EXIT

# Confirm destruction
confirm_destruction() {
    log_warning "========================================"
    log_warning "WARNING: Infrastructure Destruction"
    log_warning "========================================"
    log_warning "This will destroy ALL infrastructure including:"
    log_warning "  - EC2 instances"
    log_warning "  - VPC and networking components"
    log_warning "  - S3 state bucket (with all state history)"
    log_warning "  - DynamoDB state lock table"
    log_warning ""
    
    read -p "Are you ABSOLUTELY sure you want to destroy ALL infrastructure? (yes/no): " confirm
    
    if [ "$confirm" != "yes" ]; then
        log_info "Destruction cancelled by user."
        exit 0
    fi
    
    log_warning "Starting destruction in 5 seconds... Press Ctrl+C to cancel."
    sleep 5
}

# Validate prerequisites
validate_prerequisites() {
    log_info "Validating prerequisites..."
    
    # Check if terraform is installed
    if ! command -v terraform &> /dev/null; then
        log_error "Terraform is not installed."
        exit 1
    fi
    
    # Check if AWS CLI is configured
    if ! aws sts get-caller-identity &> /dev/null; then
        log_error "AWS CLI is not configured or credentials are invalid."
        exit 1
    fi
    
    log_success "Prerequisites validated"
}

# Destroy main infrastructure
destroy_main_infrastructure() {
    log_info "========================================"
    log_info "Step 1: Destroying Main Infrastructure"
    log_info "========================================"
    
    if [ ! -d "$MAIN_INFRA_DIR" ]; then
        log_warning "Main infrastructure directory not found. Skipping..."
        return 0
    fi
    
    cd "$MAIN_INFRA_DIR" || {
        log_error "Failed to change directory to: $MAIN_INFRA_DIR"
        exit 1
    }
    
    # Initialize if backend config exists
    if [ -f "backend.tfbackend" ]; then
        log_info "Initializing Terraform with backend configuration..."
        terraform init -backend-config=backend.tfbackend >> "$LOG_FILE" 2>&1 || {
            log_warning "Terraform init failed, attempting without backend config..."
            terraform init >> "$LOG_FILE" 2>&1 || {
                log_error "Failed to initialize Terraform"
                exit 1
            }
        }
    else
        log_warning "backend.tfbackend not found, initializing without backend..."
        terraform init >> "$LOG_FILE" 2>&1 || {
            log_error "Failed to initialize Terraform"
            exit 1
        }
    fi
    
    log_info "Destroying main infrastructure..."
    terraform destroy -auto-approve >> "$LOG_FILE" 2>&1 || {
        log_error "Failed to destroy main infrastructure"
        log_warning "Some resources may still exist. Check AWS Console."
        exit 1
    }
    
    log_success "Main infrastructure destroyed successfully"
    
    # Cleanup generated files
    log_info "Cleaning up generated files..."
    rm -f backend.tfbackend tfplan
}

# Destroy backend infrastructure
destroy_backend_infrastructure() {
    log_info "========================================"
    log_info "Step 2: Destroying Backend Infrastructure"
    log_info "========================================"
    
    if [ ! -d "$BACKEND_DIR" ]; then
        log_warning "Backend directory not found. Skipping..."
        return 0
    fi
    
    cd "$BACKEND_DIR" || {
        log_error "Failed to change directory to: $BACKEND_DIR"
        exit 1
    }
    
    log_info "Initializing Terraform for backend..."
    terraform init >> "$LOG_FILE" 2>&1 || {
        log_error "Failed to initialize backend Terraform"
        exit 1
    }
    
    log_warning "Destroying backend infrastructure (S3 bucket and DynamoDB table)..."
    log_warning "This will delete all Terraform state history!"
    
    terraform destroy -auto-approve >> "$LOG_FILE" 2>&1 || {
        log_error "Failed to destroy backend infrastructure"
        log_warning "S3 bucket or DynamoDB table may still exist. Check AWS Console."
        exit 1
    }
    
    log_success "Backend infrastructure destroyed successfully"
}

# Main execution
main() {
    log_info "Starting destruction process..."
    log_info "Log file: $LOG_FILE"
    
    confirm_destruction
    validate_prerequisites
    destroy_main_infrastructure
    destroy_backend_infrastructure
    
    log_success "========================================"
    log_success "All infrastructure destroyed successfully!"
    log_success "========================================"
    log_info "Destruction log: $LOG_FILE"
    log_info "Verify in AWS Console that all resources are removed."
}

# Run main function
main
