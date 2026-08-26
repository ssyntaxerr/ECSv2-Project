variable "name_prefix" {
  type        = string
}

variable "common_tags" {
  type        = map(string)
}

variable "queue_arn" {
  type = string
}

variable "postgres_secret_arn" {
  type = string
}