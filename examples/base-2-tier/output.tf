output "vpc_id" {
  value       = aws_vpc.this.id
  description = "VPC ID"
}

output "public_subnets" {
  value       = [aws_subnet.public_a.id, aws_subnet.public_c.id]
  description = "Public subnet IDs"
}

output "private_subnets" {
  value       = [aws_subnet.private_a.id, aws_subnet.private_c.id]
  description = "Private subnet IDs"
}

output "nat_eip" {
  value       = aws_eip.nat.public_ip
  description = "NAT EIP"
}

output "bastion_public_ip" {
  value       = aws_instance.bastion.public_ip
  description = "Bastion public IP"
}

output "web01_private_ip" {
  value       = aws_instance.web01.private_ip
  description = "Web01 private IP"
}

output "alb_dns_name" {
  value       = aws_lb.alb.dns_name
  description = "ALB DNS name"
}

output "target_group_arn" {
  value       = aws_lb_target_group.tg.arn
  description = "Target group ARN"
}
