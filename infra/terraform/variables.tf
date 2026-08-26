variable "aws_region" {
  type    = string
  default = "eu-west-2"
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "availability_zones" {
  type = list(string)
  default = [
    "eu-west-2a",
    "eu-west-2b"
  ]
}

variable "private_subnet_cidrs" {
  type = list(string)
  default = [
    "10.0.1.0/24",
    "10.0.2.0/24"
  ]
}

variable "repositories" {
  type = list(string)

  default = [
    "api-repo",
    "worker-repo",
    "dashboard-repo"
  ]
}

variable "db_username" {
  type    = string
  default = "app"
}

variable "db_password" {
  type      = string
  sensitive = true
}

variable "public_subnet_cidrs" {
  type = list(string)

  default = [
    "10.0.101.0/24",
    "10.0.102.0/24"
  ]
}

variable "certificate_arn" {
  type = string
}