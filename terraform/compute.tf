# ============================================================
# Always Free 対象の ARM (Ampere) イメージを取得
# Oracle Linux 9 - aarch64
# ============================================================
data "oci_core_images" "oracle_linux" {
  compartment_id           = var.compartment_ocid
  operating_system         = "Oracle Linux"
  operating_system_version = "9"
  shape                    = var.instance_shape
  sort_by                  = "TIMECREATED"
  sort_order               = "DESC"
}

# ============================================================
# Compute Instance
# ============================================================
resource "oci_core_instance" "n8n_instance" {
  compartment_id      = var.compartment_ocid
  availability_domain = data.oci_identity_availability_domains.ads.availability_domains[0].name
  shape               = var.instance_shape
  display_name        = "n8n-server"

  shape_config {
    ocpus         = var.instance_ocpus
    memory_in_gbs = var.instance_memory_in_gbs
  }

  source_details {
    source_type             = "image"
    source_id               = data.oci_core_images.oracle_linux.images[0].id
    boot_volume_size_in_gbs = var.boot_volume_size_in_gbs
  }

  create_vnic_details {
    subnet_id        = oci_core_subnet.n8n_subnet.id
    assign_public_ip = true
    display_name     = "n8n-vnic"
  }

  metadata = {
    ssh_authorized_keys = file(var.ssh_public_key_path)
    user_data           = base64encode(templatefile("${path.module}/cloud-init.yaml", {
      n8n_domain = var.n8n_domain
    }))
  }
}

# ============================================================
# Availability Domains
# ============================================================
data "oci_identity_availability_domains" "ads" {
  compartment_id = var.tenancy_ocid
}
