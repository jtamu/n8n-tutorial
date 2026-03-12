# n8n-tutorial

n8n のローカル開発環境と Google Cloud (Always Free) へのデプロイ環境を提供します。

## ローカル起動

```bash
docker compose up -d
```

http://localhost:5678 でアクセスできます。

## Google Cloud へのデプロイ

### 前提条件

- [Terraform](https://developer.hashicorp.com/terraform/install) (>= 1.0)
- [gcloud CLI](https://cloud.google.com/sdk/docs/install)
- [Google Cloud](https://cloud.google.com) アカウント
- SSH キーペア (`~/.ssh/id_rsa.pub`)

### 1. GCP プロジェクトの準備

```bash
# プロジェクトを作成 (既存のプロジェクトを使う場合はスキップ)
gcloud projects create my-n8n-project

# プロジェクトを設定
gcloud config set project my-n8n-project

# Compute Engine API を有効化
gcloud services enable compute.googleapis.com

# Terraform 用の認証
gcloud auth application-default login
```

### 2. Terraform 設定

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
```

`terraform.tfvars` を自分の環境に合わせて編集します。最低限 `gcp_project_id` の設定が必要です。

### 3. デプロイ

```bash
terraform init
terraform plan
terraform apply
```

完了すると以下が出力されます:

```
instance_public_ip = "34.xx.xx.xx"
n8n_url            = "http://34.xx.xx.xx:5678"
ssh_command        = "ssh n8n@34.xx.xx.xx"
```

### 4. 動作確認

```bash
# cloud-init の完了を待つ (2〜3分)
ssh n8n@<IP>
sudo cloud-init status --wait

# コンテナの確認
docker ps
```

ブラウザで `http://<IP>:5678` にアクセスして n8n の初期設定画面が表示されれば完了です。

### 5. (任意) ドメイン + HTTPS

ドメインを持っている場合、Caddy による自動 HTTPS を利用できます。

1. DNS の A レコードをインスタンスの IP に向ける
2. `terraform.tfvars` で `n8n_domain = "n8n.example.com"` を設定
3. `terraform apply` を再実行

### インフラの削除

```bash
cd terraform
terraform destroy
```

### Always Free スペック

e2-micro インスタンス (0.25 vCPU / 1GB RAM / 30GB ディスク) を使用しています。メモリが少ないため、cloud-init で 1GB の swap を自動設定しています。

Always Free 対象リージョン: `us-west1`, `us-central1`, `us-east1`
