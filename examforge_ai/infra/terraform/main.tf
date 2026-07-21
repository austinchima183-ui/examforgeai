# ============================================================================
# ExamForge AI — Infrastructure as Code (Terraform)
# ============================================================================
# Defines all infrastructure resources for the ExamForge AI platform.
#
# Architecture:
#   - Supabase (PostgreSQL + Auth + Storage + Edge Functions + Realtime)
#   - Caddy reverse proxy (security headers, TLS termination)
#   - S3-compatible storage (backups, cross-region DR)
#   - Monitoring (via Supabase tables + edge function cron)
#
# Usage:
#   terraform init
#   terraform plan -var-file=terraform.tfvars
#   terraform apply -var-file=terraform.tfvars
# ============================================================================

terraform {
  required_version = ">= 1.6.0"

  required_providers {
    supabase = {
      source  = "supabase/supabase"
      version = "~> 1.0"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Remote state storage (CRITICAL: configure for your setup)
  backend "s3" {
    bucket         = "examforge-terraform-state"
    key            = "infrastructure/terraform.tfstate"
    region         = "af-south-1"
    encrypt        = true
    dynamodb_table = "terraform-locks"
  }
}

# ════════════════════════════════════════════════════════════════════════════
# VARIABLES
# ════════════════════════════════════════════════════════════════════════════

variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "staging"

  validation {
    condition     = contains(["development", "staging", "production"], var.environment)
    error_message = "Environment must be development, staging, or production."
  }
}

variable "supabase_project_id" {
  description = "Supabase project ID"
  type        = string
  sensitive   = true
}

variable "supabase_access_token" {
  description = "Supabase access token"
  type        = string
  sensitive   = true
}

variable "supabase_db_password" {
  description = "Supabase database password"
  type        = string
  sensitive   = true
}

variable "flutterwave_secret_key" {
  description = "Flutterwave secret key for payment processing"
  type        = string
  sensitive   = true
}

variable "flutterwave_webhook_hash" {
  description = "Flutterwave webhook verification hash"
  type        = string
  sensitive   = true
}

variable "backup_bucket_name" {
  description = "S3 bucket name for backups"
  type        = string
  default     = "examforge-backups"
}

variable "dr_bucket_name" {
  description = "S3 bucket name for disaster recovery"
  type        = string
  default     = "examforge-backups-dr"
}

variable "aws_region" {
  description = "Primary AWS region"
  type        = string
  default     = "af-south-1"
}

variable "dr_aws_region" {
  description = "DR AWS region"
  type        = string
  default     = "eu-west-1"
}

variable "allowed_webhook_ips" {
  description = "IP addresses allowed to call webhook endpoints"
  type        = list(string)
  default     = []
}

variable "app_domain" {
  description = "Primary application domain"
  type        = string
  default     = "examforge.ai"
}

# ════════════════════════════════════════════════════════════════════════════
# PROVIDERS
# ════════════════════════════════════════════════════════════════════════════

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "ExamForge-AI"
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  }
}

provider "aws" {
  alias  = "dr"
  region = var.dr_aws_region

  default_tags {
    tags = {
      Project     = "ExamForge-AI"
      Environment = var.environment
      ManagedBy   = "terraform"
      Purpose     = "disaster-recovery"
    }
  }
}

# ════════════════════════════════════════════════════════════════════════════
# S3 BACKUP BUCKETS
# ════════════════════════════════════════════════════════════════════════════

resource "aws_s3_bucket" "backups" {
  bucket = "${var.backup_bucket_name}-${var.environment}"

  lifecycle {
    prevent_destroy = var.environment == "production" ? true : false
  }
}

resource "aws_s3_bucket_versioning" "backups" {
  bucket = aws_s3_bucket.backups.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "backups" {
  bucket = aws_s3_bucket.backups.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "backups" {
  bucket = aws_s3_bucket.backups.id

  rule {
    id     = "daily-backup-retention"
    status = "Enabled"

    filter {
      prefix = "daily/"
    }

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = 90
      storage_class = "GLACIER"
    }

    expiration {
      days = 365
    }
  }

  rule {
    id     = "monthly-backup-retention"
    status = "Enabled"

    filter {
      prefix = "monthly/"
    }

    transition {
      days          = 90
      storage_class = "STANDARD_IA"
    }

    expiration {
      days = 730 # 2 years
    }
  }
}

resource "aws_s3_bucket_public_access_block" "backups" {
  bucket = aws_s3_bucket.backups.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ─── DR Bucket (different region) ─────────────────────────────────────────

resource "aws_s3_bucket" "dr_backups" {
  provider = aws.dr
  bucket   = "${var.dr_bucket_name}-${var.environment}"

  lifecycle {
    prevent_destroy = var.environment == "production" ? true : false
  }
}

resource "aws_s3_bucket_versioning" "dr_backups" {
  provider = aws.dr
  bucket   = aws_s3_bucket.dr_backups.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "dr_backups" {
  provider = aws.dr
  bucket   = aws_s3_bucket.dr_backups.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "dr_backups" {
  provider = aws.dr
  bucket   = aws_s3_bucket.dr_backups.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ════════════════════════════════════════════════════════════════════════════
# IAM POLICIES (Least Privilege)
# ════════════════════════════════════════════════════════════════════════════

# Backup service account — can only write to backup bucket
resource "aws_iam_user" "backup_service" {
  name = "examforge-backup-${var.environment}"
}

resource "aws_iam_policy" "backup_write" {
  name        = "examforge-backup-write-${var.environment}"
  description = "Allow writing backups to S3"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.backups.arn,
          "${aws_s3_bucket.backups.arn}/*"
        ]
      }
    ]
  })
}

resource "aws_iam_user_policy_attachment" "backup_write" {
  user       = aws_iam_user.backup_service.name
  policy_arn = aws_iam_policy.backup_write.arn
}

# ════════════════════════════════════════════════════════════════════════════
# MONITORING RESOURCES
# ════════════════════════════════════════════════════════════════════════════

resource "aws_cloudwatch_log_group" "app_logs" {
  count             = var.environment == "production" ? 1 : 0
  name              = "/examforge/${var.environment}/app"
  retention_in_days = 90

  tags = {
    LogType = "application"
  }
}

resource "aws_cloudwatch_log_group" "security_logs" {
  count             = var.environment == "production" ? 1 : 0
  name              = "/examforge/${var.environment}/security"
  retention_in_days = 365  # Security logs kept for 1 year

  tags = {
    LogType = "security"
  }
}

resource "aws_cloudwatch_log_group" "payment_logs" {
  count             = var.environment == "production" ? 1 : 0
  name              = "/examforge/${var.environment}/payment"
  retention_in_days = 365  # Payment logs kept for 1 year (compliance)

  tags = {
    LogType = "payment"
  }
}

resource "aws_cloudwatch_log_group" "audit_logs" {
  count             = var.environment == "production" ? 1 : 0
  name              = "/examforge/${var.environment}/audit"
  retention_in_days = 2555  # Audit logs kept for 7 years (compliance)

  tags = {
    LogType = "audit"
  }
}

# ════════════════════════════════════════════════════════════════════════════
# OUTPUTS
# ════════════════════════════════════════════════════════════════════════════

output "backup_bucket_arn" {
  value = aws_s3_bucket.backups.arn
}

output "dr_bucket_arn" {
  value = aws_s3_bucket.dr_backups.arn
}

output "backup_service_user_arn" {
  value = aws_iam_user.backup_service.arn
}

output "environment" {
  value = var.environment
}
