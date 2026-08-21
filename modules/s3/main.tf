locals {
  s3_common_config = {
    block_public_acls       = true
    block_public_policy     = true
    ignore_public_acls      = true
    restrict_public_buckets = true
  }
}

# ------------------------------------------------------------------------------
# Bucket principale applicazione
# ------------------------------------------------------------------------------

resource "aws_s3_bucket" "mio_bucket" {
  bucket        = "${var.s3_bucket_name}-${var.environment}"
  force_destroy = true

  tags = {
    Name        = "${var.s3_bucket_name}-${var.environment}"
    Environment = var.environment
  }
}

resource "aws_s3_bucket_versioning" "mio_bucket" {
  bucket = aws_s3_bucket.mio_bucket.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "mio_bucket" {
  bucket = aws_s3_bucket.mio_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_public_access_block" "mio_bucket" {
  bucket                  = aws_s3_bucket.mio_bucket.id
  block_public_acls       = local.s3_common_config.block_public_acls
  block_public_policy     = local.s3_common_config.block_public_policy
  ignore_public_acls      = local.s3_common_config.ignore_public_acls
  restrict_public_buckets = local.s3_common_config.restrict_public_buckets
}

resource "aws_s3_bucket_logging" "mio_bucket" {
  bucket        = aws_s3_bucket.mio_bucket.id
  target_bucket = aws_s3_bucket.log_bucket.id
  target_prefix = "log/"
}

# ------------------------------------------------------------------------------
# Bucket log di accesso
# ------------------------------------------------------------------------------

resource "aws_s3_bucket" "log_bucket" {
  bucket        = "${var.s3_log_bucket_name}-${var.environment}"
  force_destroy = true

  tags = {
    Name        = "${var.s3_log_bucket_name}-${var.environment}"
    Environment = var.environment
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "log_bucket" {
  bucket = aws_s3_bucket.log_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_public_access_block" "log_bucket" {
  bucket                  = aws_s3_bucket.log_bucket.id
  block_public_acls       = local.s3_common_config.block_public_acls
  block_public_policy     = local.s3_common_config.block_public_policy
  ignore_public_acls      = local.s3_common_config.ignore_public_acls
  restrict_public_buckets = local.s3_common_config.restrict_public_buckets
}