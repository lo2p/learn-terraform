variable "name_prefix" {
  type = string
}

variable "public_subnet_id" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}
