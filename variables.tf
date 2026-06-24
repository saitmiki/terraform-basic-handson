variable "region" {
  description = "デプロイ先の AWS リージョン"
  type        = string
  default     = "ap-northeast-1"
}

variable "project_name" {
  description = "リソース名・タグの接頭辞"
  type        = string
  default     = "tf-handson"
}

variable "vpc_cidr" {
  description = "VPC の CIDR ブロック"
  type        = string
}

variable "public_subnet_cidr" {
  description = "Public Subnet の CIDR ブロック"
  type        = string
}

variable "availability_zone" {
  description = "Public Subnet を配置する AZ"
  type        = string
}

variable "instance_type" {
  description = "EC2 のインスタンスタイプ"
  type        = string
  default     = "t3.micro"
}

variable "ami_id" {
  description = "EC2 で利用する AMI ID"
  type        = string
}

variable "ssh_ingress_cidr" {
  description = "SSH (22番ポート) を許可する送信元 CIDR"
  type        = string
  default     = "0.0.0.0/0"
}
