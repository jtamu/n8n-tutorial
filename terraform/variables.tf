# ============================================================
# GCP 設定
# ============================================================
variable "gcp_project_id" {
  description = "GCP プロジェクト ID"
  type        = string
}

variable "gcp_region" {
  description = "GCP リージョン (Always Free: us-west1, us-central1, us-east1)"
  type        = string
  default     = "us-west1"
}

variable "gcp_zone" {
  description = "GCP ゾーン"
  type        = string
  default     = "us-west1-b"
}

# ============================================================
# インスタンス設定
# ============================================================
variable "ssh_public_key_path" {
  description = "SSH 公開鍵のパス"
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}

variable "ssh_user" {
  description = "SSH ユーザー名"
  type        = string
  default     = "n8n"
}

# ============================================================
# n8n 設定
# ============================================================
variable "n8n_domain" {
  description = "n8n にアクセスするドメイン名 (空の場合はパブリック IP を使用)"
  type        = string
  default     = ""
}

variable "n8n_encryption_key" {
  description = "n8n のワークフロー認証情報を暗号化するキー"
  type        = string
  sensitive   = true
}

variable "allowed_ips" {
  description = "アクセスを許可する IP アドレスのリスト (CIDR 形式, 例: [\"203.0.113.10/32\"])"
  type        = list(string)
  default     = []
}

# ============================================================
# Cloudflare 設定
# ============================================================
variable "cloudflare_api_token" {
  description = "Cloudflare API トークン (DNS 編集権限が必要)"
  type        = string
  sensitive   = true
}

variable "cloudflare_zone_id" {
  description = "Cloudflare の jtamu.com ゾーン ID"
  type        = string
}
