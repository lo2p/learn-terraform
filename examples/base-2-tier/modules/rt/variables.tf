variable "name_prefix" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "igw_id" {
  type = string
}

variable "nat_gateway_id" {
  type = string
}

variable "public_subnet_ids" {
  type = list(string)
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "public_subnet_count" {
  type = number
}

variable "private_subnet_count" {
  type = number
}

variable "tags" {
  type    = map(string)
  default = {}
}
