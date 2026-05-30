terraform {
  required_version = ">= 1.6"
  required_providers {
    aws = { source = "hashicorp/aws", version = "~> 5.0" }
  }
}

provider "aws" {
  region  = "us-east-1"
  profile = "default"
}

# ── COMPLIANT: KMS encryption, public access blocked, all tags ──────────────
resource "aws_s3_bucket" "good" {
  bucket = "lab33-good-bucket"
  tags = {
    project          = "lab33"
    environment      = "dev"
    managed_by       = "terraform"
    compliance_scope = "cge-p-lab"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "good" {
  bucket = aws_s3_bucket.good.id
  rule {
    apply_server_side_encryption_by_default { sse_algorithm = "aws:kms" }
  }
}

resource "aws_s3_bucket_public_access_block" "good" {
  bucket                  = aws_s3_bucket.good.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ── SC-28 VIOLATION: AES256 only, not KMS ───────────────────────────────────
resource "aws_s3_bucket" "bad_no_kms" {
  bucket = "lab33-bad-no-kms"
  tags = {
    project          = "lab33"
    environment      = "dev"
    managed_by       = "terraform"
    compliance_scope = "cge-p-lab"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "bad_no_kms" {
  bucket = aws_s3_bucket.bad_no_kms.id
  rule {
    apply_server_side_encryption_by_default { sse_algorithm = "AES256" }
  }
}

resource "aws_s3_bucket_public_access_block" "bad_no_kms" {
  bucket                  = aws_s3_bucket.bad_no_kms.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ── AC-3 VIOLATION: public access not blocked ────────────────────────────────
resource "aws_s3_bucket" "bad_public" {
  bucket = "lab33-bad-public"
  tags = {
    project          = "lab33"
    environment      = "dev"
    managed_by       = "terraform"
    compliance_scope = "cge-p-lab"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "bad_public" {
  bucket = aws_s3_bucket.bad_public.id
  rule {
    apply_server_side_encryption_by_default { sse_algorithm = "aws:kms" }
  }
}

resource "aws_s3_bucket_public_access_block" "bad_public" {
  bucket                  = aws_s3_bucket.bad_public.id
  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# ── CM-6 VIOLATION: no tags ──────────────────────────────────────────────────
resource "aws_s3_bucket" "bad_no_tags" {
  bucket = "lab33-bad-no-tags"
}

resource "aws_s3_bucket_server_side_encryption_configuration" "bad_no_tags" {
  bucket = aws_s3_bucket.bad_no_tags.id
  rule {
    apply_server_side_encryption_by_default { sse_algorithm = "aws:kms" }
  }
}

resource "aws_s3_bucket_public_access_block" "bad_no_tags" {
  bucket                  = aws_s3_bucket.bad_no_tags.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ── AC-3 VIOLATION: SSH open to internet ─────────────────────────────────────
resource "aws_security_group" "open_ssh" {
  name        = "lab33-open-ssh"
  description = "Demo SG - intentionally non-compliant"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}