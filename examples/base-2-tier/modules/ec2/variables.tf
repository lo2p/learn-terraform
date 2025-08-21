variable "name_prefix" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "private_subnets" {
  type = list(string)
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "instance_count" {
  type = number
}

variable "instance_type" {
  type = string
}

variable "key_name" {
  type = string
}

variable "ec2_sg_id" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}
