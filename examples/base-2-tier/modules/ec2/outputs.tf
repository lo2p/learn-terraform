output "instance_ids" {
  value = [for i in aws_instance.app : i.id]
}
