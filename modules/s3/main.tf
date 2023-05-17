resource "aws_s3_bucket" "Bucket" {
  bucket = var.bucketName

  website {
    index_document = var.indexDocument
  }
}

resource "aws_s3_bucket_ownership_controls" "BucketOwnership" {
  bucket = aws_s3_bucket.Bucket.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_public_access_block" "OffBlockPublicAcces" {
  bucket = aws_s3_bucket.Bucket.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_acl" "example" {
  depends_on = [
    aws_s3_bucket_ownership_controls.BucketOwnership,
    aws_s3_bucket_public_access_block.OffBlockPublicAcces,
  ]

  bucket = aws_s3_bucket.Bucket.id
  acl    = "public-read"
}

resource "aws_s3_bucket_cors_configuration" "BucketCors" {
  bucket = aws_s3_bucket.Bucket.id

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET", "HEAD", "POST", "PUT", "DELETE"]
    allowed_origins = ["*"]
    expose_headers  = []
  }
}

resource "aws_s3_object" "uploadedFolder" {
  bucket     = var.bucketName
  key        = "uploaded/"
  acl        = "public-read"
  depends_on = [aws_s3_bucket.Bucket, aws_s3_bucket_ownership_controls.BucketOwnership, aws_s3_bucket_public_access_block.OffBlockPublicAcces, aws_s3_bucket_acl.example]
}

resource "aws_s3_object" "uploadedFolder2" {
  bucket     = var.bucketName
  key        = "processed/"
  acl        = "public-read"
  depends_on = [aws_s3_bucket.Bucket, aws_s3_bucket_ownership_controls.BucketOwnership, aws_s3_bucket_public_access_block.OffBlockPublicAcces, aws_s3_bucket_acl.example]
}

locals {
  zip_file_path = "/home/ec2-user/environment/Terraform/MP4TOMP3/modules/s3/mypackage.zip"
}

resource "aws_s3_object" "uploadPackageFile" {
  bucket     = var.bucketName
  key        = "mypackage.zip"
  source     = local.zip_file_path
  depends_on = [aws_s3_bucket.Bucket, aws_s3_bucket_ownership_controls.BucketOwnership, aws_s3_bucket_public_access_block.OffBlockPublicAcces, aws_s3_bucket_acl.example]
}

output "bucket_name" {
  value = aws_s3_bucket.Bucket.id
}

output "bucket_arn" {
  value = aws_s3_bucket.Bucket.arn
}

output "bucketName" {
  value = var.bucketName
}