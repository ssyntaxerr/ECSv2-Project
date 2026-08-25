variable "name_prefix" {
  type = string
}

variable "common_tags" {
  type = map(string)
}

variable "db_username" {
  type = string
}

variable "db_password" {
  type = string
  sensitive = true
}