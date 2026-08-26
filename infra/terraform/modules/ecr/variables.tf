variable "name_prefix" {
  type = string
}

variable "common_tags" {
  type = map(string)
}

variable "repositories" {
  type = list(string)

  default = [
    "api-repo",
    "worker-repo",
    "dashboard-repo"
  ]
}