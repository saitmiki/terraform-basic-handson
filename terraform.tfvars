# CIDR や AMI など環境依存値はここで設定する。
# 機微情報（アクセスキー等）は記載しないこと。

region             = "ap-northeast-1"
project_name       = "tf-handson"
vpc_cidr           = "10.0.0.0/16"
public_subnet_cidr = "10.0.1.0/24"
availability_zone  = "ap-northeast-1a"
instance_type      = "m8.large"

# 利用リージョンの Amazon Linux 2023 などの AMI ID に書き換えること
ami_id = "xxx"

# 検証用。本番では自分の IP/32 など絞ること
ssh_ingress_cidr = "0.0.0.0/0"
