######
# S3
######

resource "aws_s3_bucket" "gtp-app-prod" {
  bucket = "gtp-app-prod-bucket"

  tags = {
    Name        = "gtp-app-prod"
    Environment = "Production"
  }
}

resource "aws_s3_bucket_ownership_controls" "gtp-app-prod" {
  bucket = aws_s3_bucket.gtp-app-prod.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "gtp-app-prod" {
  depends_on = [aws_s3_bucket_ownership_controls.gtp-app-prod]

  bucket = aws_s3_bucket.gtp-app-prod.id
  acl    = "private"
}

resource "aws_s3_bucket_public_access_block" "gtp-app-prod" {
  bucket = aws_s3_bucket.gtp-app-prod.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
