output "s3_bucket_name" {
  description = "S3 bucket used for Terraform state"
  value       = aws_s3_bucket.state_bucket.bucket
}

output "dynamodb_table_name" {
  description = "DynamoDB table used for state locking"
  value       = aws_dynamodb_table.state_lock_table.name
}

output "aws_region" {
  description = "AWS region where backend resources are deployed"
  value       = var.aws_region
}
