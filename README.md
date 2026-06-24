# Terraform Basic Handson — AWS EC2 (Public Subnet)

Terraform を使って AWS の Public Subnet 上に EC2 を構築するハンズオン用プロジェクトです。
実行環境は **HCP Terraform (Terraform Cloud)**、AWS との認証は **OIDC (Dynamic Provider Credentials)** を利用します。
ソース管理は **GitHub**、HCP Terraform の Workspace を GitHub と **VCS 連携**し、push をトリガーに `plan` が自動実行されます。

## アーキテクチャ

```
VPC (10.0.0.0/16)
└── Public Subnet (10.0.1.0/24)
    └── EC2 (パブリック IP 付与)

Internet Gateway ── Route Table (0.0.0.0/0 → IGW) ── Public Subnet
Security Group (SSH 22 許可 / アウトバウンド全許可)
```

作成するリソース:

- VPC
- Internet Gateway
- Public Subnet
- Route Table（IGW へのデフォルトルート）+ Subnet 関連付け
- Security Group
- EC2 インスタンス（Public Subnet 上、パブリック IP 付与）

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

## ファイル構成

```
.
├── CLAUDE.md          # Claude Code 用ガイドライン
├── README.md          # 本ファイル
├── .gitignore         # .terraform/ や *.tfstate などを除外
├── provider.tf        # terraform / provider ブロック（HCP Terraform backend, required_providers）
├── variables.tf       # 変数定義
├── terraform.tfvars   # 変数の値（CIDR / AMI など）
├── main.tf            # VPC / Subnet / IGW / Route Table / SG / EC2
└── outputs.tf         # EC2 のパブリック IP などを出力
```

## 前提条件

- [VSCode](https://code.visualstudio.com/) ＋ HashiCorp Terraform 拡張機能
- [Terraform CLI](https://developer.hashicorp.com/terraform/install) v1.6 以上（ローカルでの `fmt` / `validate` 用）
- GitHub アカウントとリポジトリ
- HCP Terraform (Terraform Cloud) のアカウントと organization
- AWS アカウント（OIDC 連携の設定権限を持つこと）

## 事前準備

### 1. AWS 側（OIDC 連携）

アクセスキーは使用しません。AWS 側に事前に以下を用意します。

- HCP Terraform 用の **OIDC Identity Provider**
- HCP Terraform が AssumeRole する **IAM Role**
  - 信頼ポリシーで HCP Terraform（対象 organization / workspace）を許可
  - VPC・EC2 などを作成できる権限を付与

### 2. HCP Terraform 側（GitHub VCS 連携）

1. HCP Terraform で GitHub を **VCS Provider** として接続（OAuth / GitHub App）
2. Workspace を **VCS-driven workflow** で作成し、対象の GitHub リポジトリを選択
3. Working Directory / ブランチ（例: `main`）を指定
4. `provider.tf` の `cloud` ブロックの `organization` を自分の organization 名に書き換える
   （Workspace 名はデフォルトで `tf-handson-aws`）
5. Workspace の **環境変数 (Environment variables)** に以下を設定する

   | キー | 値 | 種別 |
   | --- | --- | --- |
   | `TFC_AWS_PROVIDER_AUTH` | `true` | env |
   | `TFC_AWS_RUN_ROLE_ARN` | `arn:aws:iam::<account-id>:role/<role-name>` | env |

> state は HCP Terraform 側で管理されるため、ローカルの `*.tfstate` はコミットしません（`.gitignore` 済み）。

### 3. 変数の設定

VSCode で `terraform.tfvars` を編集します。特に `ami_id` は利用リージョンの有効な AMI に書き換えてください。

| 変数名 | 用途 | 例 |
| --- | --- | --- |
| `region` | デプロイ先リージョン | `ap-northeast-1` |
| `project_name` | リソース名・タグの接頭辞 | `tf-handson` |
| `vpc_cidr` | VPC の CIDR | `10.0.0.0/16` |
| `public_subnet_cidr` | Public Subnet の CIDR | `10.0.1.0/24` |
| `availability_zone` | サブネットの AZ | `ap-northeast-1a` |
| `instance_type` | EC2 のインスタンスタイプ | `t3.micro` |
| `ami_id` | EC2 の AMI | `ami-xxxxxxxx` |
| `ssh_ingress_cidr` | SSH を許可する送信元 CIDR | `0.0.0.0/0`（本番は要絞り込み） |

## 作業フロー（VCS 駆動）

```bash
# 1. VSCode で .tf / terraform.tfvars を編集

# 2. ローカルでフォーマット / 構文チェック
terraform fmt
terraform validate

# 3. GitHub に反映
git add .
git commit -m "..."
git push
```

4. push をトリガーに HCP Terraform で `plan` が**自動実行**される（UI で内容を確認）
5. 問題なければ HCP Terraform の **UI 上で `apply` を承認・実行**する（ローカルからは実行しない）
6. `outputs` から EC2 のパブリック IP を確認して接続テスト

> `terraform validate` をローカルで実行する場合は、初回のみ `terraform login` と `terraform init` が必要です。

## 接続テスト

apply 後、HCP Terraform の UI または `outputs` でパブリック IP を確認し、SSH で接続します
（鍵やユーザーは利用 AMI に合わせてください）。

```bash
ssh ec2-user@<instance_public_ip>
```

## 後片付け

ハンズオン終了後は必ずリソースを削除します。HCP Terraform の UI から **Destruction → Queue destroy plan** を実行してください。

## 注意事項

- AWS のアクセスキー / シークレットキーをコードや tfvars に書かない（OIDC を使用）
- `terraform.tfvars` に機微情報を含めない
- `*.tfstate` はコミットしない（HCP Terraform が管理。`.gitignore` 済み）
- `ssh_ingress_cidr` を `0.0.0.0/0` のままにしない（検証用途のみ）
- 使い終わったらリソースを削除し、不要な課金を防ぐ
# terraform-basic-handson
