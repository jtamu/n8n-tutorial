# ============================================================
# VPC ネットワーク
# ============================================================
resource "google_compute_network" "n8n_vpc" {
  name                    = "n8n-vpc"
  auto_create_subnetworks = false
}

# ============================================================
# サブネット
# ============================================================
resource "google_compute_subnetwork" "n8n_subnet" {
  name          = "n8n-subnet"
  ip_cidr_range = "10.0.1.0/24"
  network       = google_compute_network.n8n_vpc.id
}

# ============================================================
# ファイアウォールルール
# ============================================================

# SSH
resource "google_compute_firewall" "allow_ssh" {
  name    = "n8n-allow-ssh"
  network = google_compute_network.n8n_vpc.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["n8n-server"]
}

# HTTP/HTTPS - ACME チャレンジのため全 IP 許可 (Caddy がアプリレベルで IP 制限)
resource "google_compute_firewall" "allow_http" {
  name    = "n8n-allow-http"
  network = google_compute_network.n8n_vpc.name

  allow {
    protocol = "tcp"
    ports    = ["80", "443"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["n8n-server"]
}

# n8n 直アクセス - allowed_ips が空の場合は全開放
resource "google_compute_firewall" "allow_n8n" {
  name    = "n8n-allow-n8n"
  network = google_compute_network.n8n_vpc.name

  allow {
    protocol = "tcp"
    ports    = ["5678"]
  }

  source_ranges = length(var.allowed_ips) > 0 ? var.allowed_ips : ["0.0.0.0/0"]
  target_tags   = ["n8n-server"]
}

# ICMP
resource "google_compute_firewall" "allow_icmp" {
  name    = "n8n-allow-icmp"
  network = google_compute_network.n8n_vpc.name

  allow {
    protocol = "icmp"
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["n8n-server"]
}
