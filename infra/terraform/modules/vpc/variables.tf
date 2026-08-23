variable "name_prefix" {
    type = string
}

variable "common_tags" {
    type = map(string)
}

variable "vpc_cidr" {
    type = string
}

variable "availability_zone" {
    type = list(string)
}

variable "private_subnet_cidrs" {
    type = list(string)
}