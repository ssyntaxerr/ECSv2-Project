output "state_bucket_name" {
  value = aws_s3_bucket.terraform_state.bucket
}

output "acm_certificate_arn" {
  value = aws_acm_certificate_validation.main.certificate_arn
}