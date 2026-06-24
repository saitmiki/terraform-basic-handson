output "vpc_id" {
  description = "作成した VPC の ID"
  value       = aws_vpc.this.id
}

output "public_subnet_id" {
  description = "作成した Public Subnet の ID"
  value       = aws_subnet.public.id
}

output "instance_id" {
  description = "EC2 インスタンスの ID"
  value       = aws_instance.this.id
}

output "instance_public_ip" {
  description = "EC2 のパブリック IP アドレス"
  value       = aws_instance.this.public_ip
}

output "instance_public_dns" {
  description = "EC2 のパブリック DNS 名"
  value       = aws_instance.this.public_dns
}
