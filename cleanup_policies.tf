# ------------------------------------------------------------------------------
# 1. ECR Lifecycle Policy (Applicata a tutti i repository ECR del progetto)
# ------------------------------------------------------------------------------
resource "aws_ecr_lifecycle_policy" "ecr_cleanup" {
  for_each = toset([
    "llm-gateway",
    "ml-recommendations-api",
    "ml-recommendations-trainer"
  ])

  repository = each.value

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Elimina le immagini piu vecchie mantenendo solo le ultime 5"
        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = 5
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}

# ------------------------------------------------------------------------------
# 2. S3 Lifecycle Policy (Cancella file/log vecchi oltre 30 giorni)
# ------------------------------------------------------------------------------
resource "aws_s3_bucket_lifecycle_configuration" "ml_bucket_cleanup" {
  bucket = "kris-ecommerce-ml-dev"

  rule {
    id     = "delete-old-artifacts-and-logs"
    status = "Enabled"

    # Cancella automaticamente i file/dataset non aggiornati da 30 giorni
    expiration {
      days = 30
    }

    # Annulla ed elimina caricamenti incompleti (Multipart Uploads) fermi da 7 giorni
    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}