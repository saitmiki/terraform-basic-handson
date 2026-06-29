terraform {
  # HCP Terraform (Terraform Cloud) を実行環境として利用する
  # organization は自分の環境に合わせて書き換えること
  cloud {
    organization = "saito-mikio-terraform"

    workspaces {
      name = "tf-handson-aws"
    }
  }

  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.26.0"
    }
  }
}

# 認証は HCP Terraform の Dynamic Provider Credentials (OIDC) で行う。
# アクセスキー / シークレットキーは記載しない。
# Workspace に以下の環境変数を設定しておくこと:
#   TFC_AWS_PROVIDER_AUTH = true
#   TFC_AWS_RUN_ROLE_ARN  = arn:aws:iam::<account-id>:role/<role-name>
provider "aws" {
  region = var.region
}
