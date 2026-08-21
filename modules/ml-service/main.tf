resource "aws_s3_bucket" "ml_models" {
  bucket        = var.bucket_name
  force_destroy = false
}

resource "aws_s3_bucket_versioning" "ml_models_versioning" {
  bucket = aws_s3_bucket.ml_models.id
  versioning_configuration { status = "Enabled" }
}

resource "aws_s3_bucket_public_access_block" "ml_models" {
  bucket                  = aws_s3_bucket.ml_models.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_ecr_repository" "ml_api" {
  name                 = "ml-recommendations-api"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_ecr_repository" "ml_trainer" {
  name                 = "ml-recommendations-trainer"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_iam_user" "k8s_ml_user" {
  name = "k8s-mlops-s3-user-${var.environment}"
}

resource "aws_iam_access_key" "k8s_ml_user_key" {
  user = aws_iam_user.k8s_ml_user.name
}

resource "aws_iam_user_policy" "k8s_ml_s3_policy" {
  name = "k8s-mlops-s3-access"
  user = aws_iam_user.k8s_ml_user.name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["s3:GetObject", "s3:PutObject", "s3:ListBucket"]
      Resource = [aws_s3_bucket.ml_models.arn, "${aws_s3_bucket.ml_models.arn}/*"]
    }]
  })
}
