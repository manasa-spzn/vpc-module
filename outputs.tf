output "vpc_id" {
  description = "The ID of the main VPC"
  value       = aws_vpc.my_vpc.id
}

output "private_subnet_ids" {
  description = "The IDs of the private subnets"
  value       = [aws_subnet.private_subnet_1.id, aws_subnet.private_subnet_2.id]
}