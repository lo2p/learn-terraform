output "alb_dns_name" {
  value = module.alb.alb_dns_name
}

output "ec2_instance_ids" {
  value = module.ec2.instance_ids
}

output "public_subnet_ids" {
  value = module.subnets.public_subnet_ids
}

output "private_subnet_ids" {
  value = module.subnets.private_subnet_ids
}

output "vpc_id" {
  value = module.vpc.vpc_id
}
