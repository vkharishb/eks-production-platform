terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.95"
    }
  }
}

provider "aws" {
  region = var.region
}

resource "aws_s3_bucket" "tf_state" {
  # was hardcoded "eks-platform-tf-state-dev" — now variable-driven for multi-env reuse
  bucket = "${var.project_name}-tf-state-${var.env}"

  tags = {
    Name = "Terraform State"
    Env  = var.env
  }
}

resource "aws_s3_bucket_public_access_block" "block" {
  bucket = aws_s3_bucket.tf_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "versioning" {
  bucket = aws_s3_bucket.tf_state.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "encryption" {
  bucket = aws_s3_bucket.tf_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Expire old non-current state versions to prevent unbounded storage growth
resource "aws_s3_bucket_lifecycle_configuration" "state_expiry" {
  bucket = aws_s3_bucket.tf_state.id

  rule {
    id     = "expire-old-state-versions"
    status = "Enabled"

    noncurrent_version_expiration {
      noncurrent_days = 90
    }

    # Clean up incomplete multipart uploads
    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }

  depends_on = [aws_s3_bucket_versioning.versioning]
}

resource "aws_dynamodb_table" "lock" {
  # was hardcoded "eks-platform-tf-state-lock-dev" — now variable-driven
  name         = "${var.project_name}-tf-state-lock-${var.env}"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}
