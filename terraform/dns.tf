# ============================================================
# Cloudflare DNS レコード
# ============================================================
resource "cloudflare_record" "n8n" {
  zone_id = var.cloudflare_zone_id
  name    = "n8n"
  content = oci_core_instance.n8n_instance.public_ip
  type    = "A"
  ttl     = 1 # Auto
  proxied = false
}
