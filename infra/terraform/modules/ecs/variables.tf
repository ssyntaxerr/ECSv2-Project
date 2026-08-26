variable "name_prefix" {
  type = string
}

variable "common_tags" {
  type = map(string)
}

variable "vpc_id" {
  type = string
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "api_image" {
  type = string
}

variable "worker_image" {
  type = string
}

variable "dashboard_image" {
  type = string
}

variable "execution_role_arn" {
  type = string
}

variable "api_task_role_arn" {
  type = string
}

variable "worker_task_role_arn" {
  type = string
}

variable "dashboard_task_role_arn" {
  type = string
}

variable "postgres_secret_arn" {
  type = string
}

variable "sqs_queue_url" {
  type = string
}

variable "db_endpoint" {
  type = string
}

variable "db_port" {
  type = number
}

variable "redis_endpoint" {
  type = string
}

variable "redis_port" {
  type = number
}

variable "aws_region" {
  type = string
}

variable "api_target_group_arn" {
  type = string
}

variable "dashboard_target_group_arn" {
  type = string
}

variable "alb_security_group_id" {
  type = string
}