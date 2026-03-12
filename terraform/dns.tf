# ============================================================
# Cloudflare DNS レコード
# ============================================================
resource "cloudflare_record" "n8n" {
  zone_id = var.cloudflare_zone_id
  name    = "n8n"
  content = google_compute_instance.n8n_instance.network_interface[0].access_config[0].nat_ip
  type    = "A"
  ttl     = 1 # Auto
  proxied = true
}
