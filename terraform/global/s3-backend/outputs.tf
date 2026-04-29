output "bucket_name" {
  description = "S3 bucket name for Terraform state"
  value       = aws_s3_bucket.tf_state.id
}

output "dynamodb_table" {
  description = "DynamoDB table name for state locking"
  value       = aws_dynamodb_table.lock.name
}
