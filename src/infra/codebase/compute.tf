resource "google_service_account" "vm" {
  account_id   = "wordpress-vm"
  display_name = "WordPress VM"
}

locals {
  vm_files = {
    "/opt/wordpress/compose.yaml" = { mode = "644", content = templatefile("${path.module}/vm/compose.yaml.tftpl", { domain = var.website_domain }) }
    "/opt/wordpress/apache.conf"  = { mode = "644", content = file("${path.module}/vm/apache.conf") }
    "/opt/wordpress/php.ini"      = { mode = "644", content = file("${path.module}/vm/php.ini") }
    "/usr/local/sbin/wp-backup"   = { mode = "755", content = file("${path.module}/vm/wp-backup.sh") }
    "/usr/local/sbin/wp-restore"  = { mode = "755", content = file("${path.module}/vm/wp-restore.sh") }
  }
}

resource "google_compute_disk" "data" {
  name = "wordpress-data"
  type = "pd-standard"
  size = 10

  lifecycle {
    prevent_destroy = true
  }
}

resource "google_compute_instance" "wordpress" {
  name                      = "wordpress-server"
  machine_type              = "e2-micro"
  tags                      = ["wordpress"]
  allow_stopping_for_update = true

  boot_disk {
    auto_delete = true
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-minimal-2404-lts-amd64"
      size  = 20
      type  = "pd-standard"
    }
  }

  attached_disk {
    source      = google_compute_disk.data.id
    device_name = "data"
  }

  network_interface {
    subnetwork = google_compute_subnetwork.wordpress.id
    access_config {
      network_tier = "STANDARD"
    }
  }

  service_account {
    email  = google_service_account.vm.email
    scopes = ["cloud-platform"]
  }

  shielded_instance_config {
    enable_secure_boot          = true
    enable_vtpm                 = true
    enable_integrity_monitoring = true
  }

  metadata = {
    enable-oslogin = "TRUE"
    startup-script = templatefile("${path.module}/vm/startup.sh.tftpl", {
      files  = local.vm_files
      bucket = google_storage_bucket.backups.name
    })
  }

  lifecycle {
    ignore_changes = [boot_disk[0].initialize_params[0].image]
  }

  depends_on = [
    google_secret_manager_secret_version.vm,
    google_secret_manager_secret_iam_member.vm,
    google_storage_bucket_iam_member.backups_writer,
  ]
}
