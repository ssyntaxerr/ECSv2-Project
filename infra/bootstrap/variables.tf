variable "aws_region" {
  type    = string
  default = "eu-west-2"
}

variable "state_bucket_name" {
  type = string
}

variable "domain_name" {
  type = string
}

variable "cloudflare_api_token" {
  type = string
  sensitive = true
}