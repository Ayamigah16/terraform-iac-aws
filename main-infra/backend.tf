# Backend configuration for remote state storage
# Note: Update the bucket name after running backend-setup
# Run: terraform init -backend-config="bucket=<your-bucket-name>"
# Or update the bucket value below after creating the S3 bucket

terraform {
  backend "s3" {
    bucket         = "terraform-iac-aws-dev-f996da4e" # Update this with your bucket name
    key            = "dev/terraform.tfstate"
    region         = "eu-west-1"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}