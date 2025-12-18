resource "random_id" "bucket_suffix" {
  byte_length = 4
}

resource "aws_s3_bucket" "state_bucket" {
  bucket = "${var.project_name}-${var.environment}-${random_id.bucket_suffix.hex}"

  tags = {
    Name        = "${var.project_name}-${var.environment}"
    Environment = var.environment
    Purpose     = "Terraform State Storage"
  }
}

# Enable versioning for state recovery
resource "aws_s3_bucket_versioning" "state_bucket_versioning" {
  bucket = aws_s3_bucket.state_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Enable server-side encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "state_bucket_encryption" {
  bucket = aws_s3_bucket.state_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Block public access
resource "aws_s3_bucket_public_access_block" "state_bucket_public_access" {
  bucket = aws_s3_bucket.state_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Enable bucket logging (optional but recommended)
resource "aws_s3_bucket_logging" "state_bucket_logging" {
  bucket = aws_s3_bucket.state_bucket.id

  target_bucket = aws_s3_bucket.state_bucket.id
  target_prefix = "logs/"
}

resource "aws_dynamodb_table" "state_lock_table" {
  name         = var.dynamodb_table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name        = var.dynamodb_table_name
    Environment = var.environment
  }
}