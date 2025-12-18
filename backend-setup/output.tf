output "s3_bucket_name" {
  description = "S3 bucket used"
  value       = aws_s3_bucket.state_bucket.bucket
}


output "dynamodb_table_name" {
  description = "DynamoDB table used for state locking"
  value       = aws_dynamodb_table.state_lock_table.name
}
