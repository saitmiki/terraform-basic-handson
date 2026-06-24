# CLAUDE.md

このリポジトリで Claude Code が作業する際のガイドラインです。
AWS 上に EC2 を構築する Terraform ハンズオン用プロジェクトです。

## プロジェクト概要

- **目的**: Terraform を使って AWS の Public Subnet に EC2 を構築するハンズオン
- **実行環境**: HCP Terraform (Terraform Cloud) ※plan / apply は HCP Terraform 上で実行する
- **認証方式**: HCP Terraform と AWS は OIDC (Dynamic Provider Credentials) で連携する
- **環境分け**: dev / uat / prod といった環境分けは行わない（単一環境）
- **エディタ**: VSCode を使用する
- **ソース管理**: GitHub を使用し、HCP Terraform の Workspace を GitHub リポジトリと VCS 連携する

## 前提環境

| 項目 | 内容 |
| --- | --- |
| エディタ | VSCode |
| ソース管理 | GitHub（リポジトリにコードを push） |
| 実行基盤 | HCP Terraform（GitHub リポジトリと VCS 連携） |
| 認証 | HCP Terraform → AWS を OIDC で連携 |

推奨する VSCode 拡張機能:

- HashiCorp Terraform（構文ハイライト・補完・`terraform fmt`）
- AWS Toolkit（任意）

ワークフローの前提:

- ローカルでは VSCode で編集し、`git push` で GitHub に反映する
- HCP Terraform は GitHub と VCS 連携しており、push をトリガーに `plan` が自動実行される
- `apply` は HCP Terraform の UI 上で承認・実行する（ローカルからは実行しない）

## アーキテクチャ

```
VPC
└── Public Subnet
    └── EC2 (パブリックIP付与)
```

構築するリソースの概要:

- VPC
- Internet Gateway
- Public Subnet
- Route Table（IGW へのデフォルトルート）+ Subnet 関連付け
- Security Group
- EC2 インスタンス（Public Subnet 上、パブリック IP 付与）

## 認証（OIDC 連携）の方針

- アクセスキー / シークレットキーは **使用しない**
- HCP Terraform の Dynamic Provider Credentials（OIDC）を利用する
- AWS 側には事前に以下を用意する想定:
  - HCP Terraform 用の OIDC Identity Provider
  - HCP Terraform が AssumeRole する IAM Role（信頼ポリシーで HCP Terraform を許可）
- Terraform 実行時に `TFC_AWS_PROVIDER_AUTH` と `TFC_AWS_RUN_ROLE_ARN` を Workspace の環境変数に設定する
- provider 定義ではアクセスキーを書かず、OIDC によって自動で認証情報が注入される

```hcl
provider "aws" {
  region = var.region
}
```

## 変数管理（tfvars）

- VPC / Subnet などの **CIDR は tfvars で設定する**
- ハードコードせず、必ず変数化する
- `variables.tf` で変数を定義し、`terraform.tfvars` で値を与える

設定する主な変数（例）:

| 変数名 | 用途 | 例 |
| --- | --- | --- |
| `region` | デプロイ先リージョン | `ap-northeast-1` |
| `vpc_cidr` | VPC の CIDR | `10.0.0.0/16` |
| `public_subnet_cidr` | Public Subnet の CIDR | `10.0.1.0/24` |
| `availability_zone` | サブネットの AZ | `ap-northeast-1a` |
| `instance_type` | EC2 のインスタンスタイプ | `t3.micro` |
| `ami_id` | EC2 の AMI | `ami-xxxxxxxx` |
| `project_name` | リソース名・タグの接頭辞 | `tf-handson` |

## ファイル構成

```
.
├── CLAUDE.md
├── .gitignore         # .terraform/ や *.tfstate などを除外
├── provider.tf        # provider / terraform ブロック（HCP Terraform backend, required_providers）
├── variables.tf       # 変数定義
├── terraform.tfvars   # 変数の値（CIDR など）
├── main.tf            # VPC / Subnet / IGW / Route Table / SG / EC2
└── outputs.tf         # EC2 のパブリックIP などを出力
```

## コーディング規約

- リソース名・タグには `var.project_name` を接頭辞として付与し、命名を統一する
- すべてのリソースに `Name` タグを付ける
- CIDR や AMI など環境依存値はハードコードせず変数化する
- `terraform fmt` でフォーマットを整える
- `terraform validate` で構文を確認する

## HCP Terraform の設定

- `terraform` ブロックの `cloud` で organization と workspace を指定する

```hcl
terraform {
  cloud {
    organization = "<your-org>"
    workspaces {
      name = "tf-handson-aws"
    }
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}
```

- Workspace に設定する環境変数（OIDC 用）:
  - `TFC_AWS_PROVIDER_AUTH = true`
  - `TFC_AWS_RUN_ROLE_ARN = arn:aws:iam::<account-id>:role/<role-name>`

### GitHub VCS 連携

- HCP Terraform の Workspace を **VCS-driven workflow** で作成し、GitHub リポジトリと連携する
- 連携することで、GitHub への push をトリガーに `plan` が自動実行される
- 設定手順（概要）:
  1. HCP Terraform で GitHub を VCS Provider として接続（OAuth / GitHub App）
  2. Workspace 作成時に対象の GitHub リポジトリを選択
  3. Working Directory / ブランチ（例: `main`）を指定
- `.gitignore` で以下を除外する:

```gitignore
.terraform/
*.tfstate
*.tfstate.*
crash.log
*.tfvars.backup
```

> 注: state は HCP Terraform 側で管理されるため、ローカルの `*.tfstate` はコミットしない。

## 作業フロー

1. VSCode で `.tf` ファイルを編集し、変数（CIDR・AMI・instance_type 等）を `terraform.tfvars` に設定
2. ローカルで `terraform fmt` / `terraform validate` を実行（構文・フォーマット確認）
3. `git add` / `git commit` / `git push` で GitHub に反映
4. push をトリガーに HCP Terraform で `plan` が自動実行される（UI で内容を確認）
5. 問題なければ HCP Terraform の UI 上で `apply` を承認・実行
6. `outputs` から EC2 のパブリック IP を確認して接続テスト

## 注意事項

- AWS のアクセスキーをコードや tfvars に書かない（OIDC を使う）
- `terraform.tfvars` に機微情報を含めない
- ハンズオン終了後は `terraform destroy` でリソースを削除する
