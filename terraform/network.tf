# ============================================================
# VCN (Virtual Cloud Network)
# ============================================================
resource "oci_core_vcn" "n8n_vcn" {
  compartment_id = var.compartment_ocid
  cidr_blocks    = ["10.0.0.0/16"]
  display_name   = "n8n-vcn"
  dns_label      = "n8nvcn"
}

# ============================================================
# Internet Gateway
# ============================================================
resource "oci_core_internet_gateway" "n8n_igw" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.n8n_vcn.id
  display_name   = "n8n-igw"
  enabled        = true
}

# ============================================================
# Route Table
# ============================================================
resource "oci_core_route_table" "n8n_rt" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.n8n_vcn.id
  display_name   = "n8n-rt"

  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_internet_gateway.n8n_igw.id
  }
}

# ============================================================
# Security List
# ============================================================
resource "oci_core_security_list" "n8n_sl" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.n8n_vcn.id
  display_name   = "n8n-security-list"

  # Egress: すべて許可
  egress_security_rules {
    protocol    = "all"
    destination = "0.0.0.0/0"
  }

  # SSH
  ingress_security_rules {
    protocol = "6" # TCP
    source   = "0.0.0.0/0"

    tcp_options {
      min = 22
      max = 22
    }
  }

  # HTTP (Caddy リバースプロキシ) - allowed_ips が空の場合は全開放
  dynamic "ingress_security_rules" {
    for_each = length(var.allowed_ips) > 0 ? var.allowed_ips : ["0.0.0.0/0"]
    content {
      protocol = "6"
      source   = ingress_security_rules.value

      tcp_options {
        min = 80
        max = 80
      }
    }
  }

  # HTTPS - allowed_ips が空の場合は全開放
  dynamic "ingress_security_rules" {
    for_each = length(var.allowed_ips) > 0 ? var.allowed_ips : ["0.0.0.0/0"]
    content {
      protocol = "6"
      source   = ingress_security_rules.value

      tcp_options {
        min = 443
        max = 443
      }
    }
  }

  # n8n 直接アクセス (ドメイン未設定時の確認用) - allowed_ips が空の場合は全開放
  dynamic "ingress_security_rules" {
    for_each = length(var.allowed_ips) > 0 ? var.allowed_ips : ["0.0.0.0/0"]
    content {
      protocol = "6"
      source   = ingress_security_rules.value

      tcp_options {
        min = 5678
        max = 5678
      }
    }
  }

  # ICMP
  ingress_security_rules {
    protocol = "1" # ICMP
    source   = "0.0.0.0/0"
  }
}

# ============================================================
# Subnet
# ============================================================
resource "oci_core_subnet" "n8n_subnet" {
  compartment_id    = var.compartment_ocid
  vcn_id            = oci_core_vcn.n8n_vcn.id
  cidr_block        = "10.0.1.0/24"
  display_name      = "n8n-subnet"
  dns_label         = "n8nsub"
  route_table_id    = oci_core_route_table.n8n_rt.id
  security_list_ids = [oci_core_security_list.n8n_sl.id]
}
