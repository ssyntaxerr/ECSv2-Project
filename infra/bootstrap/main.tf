resource "aws_s3_bucket" "terraform_state" {
  bucket = var.state_bucket_name

  tags = {
    Name        = var.state_bucket_name
    Project     = "ECSv2"
    Environment = "bootstrap"
    ManagedBy   = "Terraform"
  }
}

resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

data "cloudflare_zone" "main" {
  name = var.domain_name
}

resource "aws_acm_certificate" "main" {
  domain_name = var.domain_name
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = "${var.domain_name}-certificate"
    Project = "ECSv2"
    Environment = "bootstrap"
    ManagedBy = "Terraform"
  }
}

resource "cloudflare_record" "acm_validation" {
  zone_id = data.cloudflare_zone.main.id

  name = tolist(
    aws_acm_certificate.main.domain_validation_options
  )[0].resource_record_name

  type = "CNAME"

  value = tolist(
    aws_acm_certificate.main.domain_validation_options
  )[0].resource_record_value

  ttl = 120
  proxied = false
}