variable "region" {
  type        = string
  description = "AWS region to deploy into"
  default     = "ap-northeast-2"
}

variable "name_prefix" {
  type        = string
  description = "Name prefix for all resources"
  default     = "two-tier"
}

variable "vpc_cidr" {
  type        = string
  description = "CIDR block for the VPC"
  default     = "10.0.0.0/16"
}

variable "az_count" {
  type        = number
  description = "Number of AZs to use"
  default     = 2
}

variable "instance_count" {
  type        = number
  description = "Number of EC2 instances behind the ALB"
  default     = 2
}

variable "instance_type" {
  type        = string
  description = "Instance type for application instances"
  default     = "t3.micro"
}

variable "key_name" {
  type        = string
  description = "EC2 key pair name (must exist)"
}

variable "allowed_ssh_cidrs" {
  type        = list(string)
  description = "CIDR blocks allowed to SSH to EC2 (optional). Leave empty to disable SSH."
  default     = []
}

variable "tags" {
  type        = map(string)
  description = "Extra tags to attach to all resources"
  default     = {}
}
