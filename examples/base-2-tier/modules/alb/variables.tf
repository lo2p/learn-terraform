variable "name" {
  type = string
}

variable "security_groups" {
  type = list(string)
}

variable "subnets" {
  type = list(string)
}

variable "vpc_id" {
  type = string
}

variable "listener_port" {
  type    = number
  default = 80
}

variable "target_group_name" {
  type = string
}

variable "target_group_port" {
  type    = number
  default = 8080
}

variable "target_ids" {
  description = "List of instance IDs to register"
  type        = list(string)
}

variable "target_count" {
  description = "Number of targets"
  type        = number
}

variable "health_check_path" {
  type    = string
  default = "/"
}

variable "tags" {
  type    = map(string)
  default = {}
}
