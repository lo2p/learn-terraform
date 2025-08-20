variable "region" {
  description = "AWS region"
  type        = string
  default     = "ap-northeast-2"
}

variable "vpc_cidr" {
  description = "VPC CIDR"
  type        = string
  default     = "10.0.0.0/16"
}

variable "key_name" {
  description = "Existing EC2 Key Pair name to SSH into instances"
  type        = string
  sensitive   = true
}

variable "tags" {
  description = "Optional extra tags"
  type        = map(string)
  default     = {}
}
