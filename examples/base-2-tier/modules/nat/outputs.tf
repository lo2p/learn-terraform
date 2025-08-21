output "nat_gateway_id" {
  value = aws_nat_gateway.this.id
}

output "eip_allocation_id" {
  value = aws_eip.nat.id
}
