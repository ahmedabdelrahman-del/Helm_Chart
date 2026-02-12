output "vpc_id" {
  value = aws_vpc.this.id
}

output "azs" {
  value = local.azs
}

output "public_subnet_ids" {
  value = [for s in aws_subnet.public : s.id]
}

output "private_subnet_ids" {
  value = [for s in aws_subnet.private : s.id]
}

output "isolated_subnet_ids" {
  value = [for s in aws_subnet.isolated : s.id]
}
output "vpc_endpoint_s3_id" {
  value       = try(aws_vpc_endpoint.s3[0].id, null)
  description = "S3 gateway endpoint ID"
}

output "vpc_interface_endpoints" {
  value       = { for k, v in aws_vpc_endpoint.interface : k => v.id }
  description = "Map of interface endpoint service -> endpoint ID"
}
