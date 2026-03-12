output "instance_public_ip" {
  description = "n8n サーバーのパブリック IP"
  value       = google_compute_instance.n8n_instance.network_interface[0].access_config[0].nat_ip
}

output "n8n_url" {
  description = "n8n アクセス URL"
  value       = var.n8n_domain != "" ? "https://${var.n8n_domain}" : "http://${google_compute_instance.n8n_instance.network_interface[0].access_config[0].nat_ip}:5678"
}

output "ssh_command" {
  description = "SSH 接続コマンド"
  value       = "ssh ${var.ssh_user}@${google_compute_instance.n8n_instance.network_interface[0].access_config[0].nat_ip}"
}
