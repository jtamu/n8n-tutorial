output "instance_public_ip" {
  description = "n8n サーバーのパブリック IP"
  value       = oci_core_instance.n8n_instance.public_ip
}

output "n8n_url" {
  description = "n8n アクセス URL"
  value       = var.n8n_domain != "" ? "https://${var.n8n_domain}" : "http://${oci_core_instance.n8n_instance.public_ip}:5678"
}

output "ssh_command" {
  description = "SSH 接続コマンド"
  value       = "ssh opc@${oci_core_instance.n8n_instance.public_ip}"
}
