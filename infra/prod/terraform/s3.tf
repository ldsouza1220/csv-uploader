#######################################
# S3 Bucket for CSV Uploader WebApp
#######################################

resource "aws_s3_bucket" "csv_uploader" {
  bucket = "csv-uploader-ounass"

  tags = merge(local.tags, {
    Name = "csv-uploader-ounass"
  })
}

resource "aws_s3_bucket_lifecycle_configuration" "csv_uploader" {
  bucket = aws_s3_bucket.csv_uploader.id

  rule {
    id     = "glacier-transition"
    status = "Enabled"

    transition {
      days          = 14
      storage_class = "GLACIER"
    }
  }
}

resource "aws_s3_bucket_versioning" "csv_uploader" {
  bucket = aws_s3_bucket.csv_uploader.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "csv_uploader" {
  bucket = aws_s3_bucket.csv_uploader.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "csv_uploader" {
  bucket = aws_s3_bucket.csv_uploader.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

#######################################
# Outputs
#######################################

output "s3_bucket_name" {
  description = "S3 bucket name for CSV uploader"
  value       = aws_s3_bucket.csv_uploader.id
}

output "s3_bucket_arn" {
  description = "S3 bucket ARN for CSV uploader"
  value       = aws_s3_bucket.csv_uploader.arn
}
