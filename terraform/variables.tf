# ============================================================
# OCI 認証情報 (terraform.tfvars で設定)
# ============================================================
variable "tenancy_ocid" {
  description = "OCI テナンシーの OCID"
  type        = string
}

variable "user_ocid" {
  description = "OCI ユーザーの OCID"
  type        = string
}

variable "fingerprint" {
  description = "API キーのフィンガープリント"
  type        = string
}

variable "private_key_path" {
  description = "API 秘密鍵のパス"
  type        = string
}

variable "region" {
  description = "OCI リージョン"
  type        = string
  default     = "ap-tokyo-1"
}

variable "compartment_ocid" {
  description = "コンパートメントの OCID (テナンシー OCID と同じでも可)"
  type        = string
}

# ============================================================
# インスタンス設定
# ============================================================
variable "ssh_public_key_path" {
  description = "SSH 公開鍵のパス"
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}

variable "instance_shape" {
  description = "インスタンスのシェイプ (Always Free: VM.Standard.A1.Flex)"
  type        = string
  default     = "VM.Standard.A1.Flex"
}

variable "instance_ocpus" {
  description = "OCPU 数 (Always Free 上限: 4)"
  type        = number
  default     = 1
}

variable "instance_memory_in_gbs" {
  description = "メモリ GB (Always Free 上限: 24, OCPU あたり最大 6)"
  type        = number
  default     = 6
}

variable "boot_volume_size_in_gbs" {
  description = "ブートボリュームサイズ GB (Always Free: 最大 200GB 合計)"
  type        = number
  default     = 50
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
