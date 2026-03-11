# n8n-tutorial

n8n のローカル開発環境と Oracle Cloud (Always Free) へのデプロイ環境を提供します。

## ローカル起動

```bash
docker compose up -d
```

http://localhost:5678 でアクセスできます。

## Oracle Cloud へのデプロイ

### 前提条件

- [Terraform](https://developer.hashicorp.com/terraform/install) (>= 1.5.0)
- [Oracle Cloud](https://cloud.oracle.com) の Always Free アカウント
- SSH キーペア (`~/.ssh/id_rsa.pub`)

### 1. OCI API キーの作成

```bash
mkdir -p ~/.oci
openssl genrsa -out ~/.oci/oci_api_key.pem 2048
openssl rsa -pubout -in ~/.oci/oci_api_key.pem -out ~/.oci/oci_api_key_public.pem
chmod 600 ~/.oci/oci_api_key.pem
```

OCI コンソール → **プロファイル** → **API キー** → **公開キーの追加** で `oci_api_key_public.pem` の内容を登録します。

### 2. OCID の確認

| 値 | 確認場所 |
|---|---|
| `tenancy_ocid` | OCI コンソール → プロファイル → テナンシー |
| `user_ocid` | OCI コンソール → プロファイル → ユーザー設定 |
| `fingerprint` | API キー追加時に表示 |
| `compartment_ocid` | ルートコンパートメントなら `tenancy_ocid` と同じ |

### 3. Terraform 設定

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
```

`terraform.tfvars` を自分の環境に合わせて編集します。

### 4. デプロイ

```bash
terraform init
terraform plan
terraform apply
```

完了すると以下が出力されます:

```
instance_public_ip = "129.xx.xx.xx"
n8n_url            = "http://129.xx.xx.xx:5678"
ssh_command        = "ssh opc@129.xx.xx.xx"
```

### 5. 動作確認

```bash
# cloud-init の完了を待つ (2〜3分)
ssh opc@<IP>
sudo cloud-init status --wait

# コンテナの確認
docker ps
```

ブラウザで `http://<IP>:5678` にアクセスして n8n の初期設定画面が表示されれば完了です。

### 6. (任意) ドメイン + HTTPS

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

デフォルトでは ARM 1 OCPU / 6GB RAM を使用しています。`terraform.tfvars` で最大 4 OCPU / 24GB RAM まで無料枠内で変更可能です。
