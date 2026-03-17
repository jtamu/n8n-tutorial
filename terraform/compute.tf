# ============================================================
# Compute Instance (Always Free: e2-micro)
# ============================================================
resource "google_compute_instance" "n8n_instance" {
  name         = "n8n-server"
  machine_type = "e2-micro"

  tags = ["n8n-server"]

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-12"
      size  = 30 # GB (Always Free 上限: 30GB)
      type  = "pd-standard"
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.n8n_subnet.id

    access_config {
      nat_ip = google_compute_address.n8n_ip.address
    }
  }

  metadata = {
    ssh-keys       = "${var.ssh_user}:${file(var.ssh_public_key_path)}"
    enable-oslogin = "TRUE"
    user-data = templatefile("${path.module}/cloud-init.yaml", {
      n8n_domain         = var.n8n_domain
      n8n_encryption_key = var.n8n_encryption_key
      allowed_ips        = var.allowed_ips
    })
  }

  # cloud-init を有効にするためのスクリプト
  metadata_startup_script = <<-EOT
    if [ ! -f /var/log/cloud-init-done ]; then
      apt-get update && apt-get install -y cloud-init
      cloud-init init --local
      cloud-init init
      cloud-init modules --mode=config
      cloud-init modules --mode=final
      touch /var/log/cloud-init-done
    fi
  EOT
}

# ============================================================
# 外部 IP の予約 (Always Free: 1 つ無料)
# ============================================================
resource "google_compute_address" "n8n_ip" {
  name = "n8n-server-ip"
}
