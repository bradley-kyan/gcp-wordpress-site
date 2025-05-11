resource "google_compute_instance" "vm_instance" {
  name         = "wordpress-server"
  machine_type = "e2-micro"
  network_interface {
    network = "default"
    access_config {
      network_tier = "STANDARD"
    }
  }
  boot_disk {
    auto_delete = false
    initialize_params {
      image = "ubuntu-minimal-2204-jammy-v20250502"
      size  = 30
      type  = "pd-standard"
    }
  }

  tags = ["web", "http-server", "https-server"]

  metadata_startup_script = <<EOF
    touch ~/hcp-init-installer.sh
    echo "apt-get update && apt install apt-utils && apt-get install ca-certificates
    wget https://raw.githubusercontent.com/hestiacp/hestiacp/release/install/hst-install.sh &&
    bash hst-install.sh --interactive no --email kyan@kbradl.com --username kbradl --password ${random_password.hestiacp_password.result} --hostname hcp.${var.website_domain} -f &&
    reboot" > ~/hcp-init-installer.sh
  EOF
}

resource "google_compute_firewall" "wordpress_firewall" {
  name        = "wordpress-firewall"
  network     = google_compute_instance.vm_instance.network_interface[0].network
  description = "Allow HTTP and HTTPS traffic to the WordPress VM instance"
  direction   = "INGRESS"

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["http-server", "https-server"]
  allow {
    protocol = "tcp"
    ports = [
      "80",   # HTTP
      "8080", # Alternative HTTP
      "443",  # HTTPS
      "8443", # Alternative HTTPS
      "465",  # SMTP over SSL
      "587",  # SMTP (submission)
      "53",   # DNS
      "143",  # IMAP
      "993",  # IMAP over SSL
      "110",  # POP3
      "995",  # POP3 over SSL
      "25"    # SMTP (relay)
    ]
  }

  allow {
    protocol = "udp"
    ports    = ["53"]
  }
}

resource "google_compute_firewall" "hestia_access_firewall" {
  name          = "ingress-hestiacp"
  network       = google_compute_instance.vm_instance.network_interface[0].network
  source_ranges = ["0.0.0.0/0"]
  direction     = "INGRESS"

  target_tags = ["web"]
  allow {
    protocol = "tcp"
    ports    = ["8083"]
  }
}

resource "google_compute_firewall" "hestia_egress_firewall" {
  name    = "egress-hestiacp"
  network = google_compute_instance.vm_instance.network_interface[0].network

  direction     = "EGRESS"
  target_tags   = ["web"]
  source_ranges = ["0.0.0.0/0"]

  allow {
    protocol = "tcp"
    ports    = ["465", "587", "53", "143", "993", "110", "995"]
  }

  allow {
    protocol = "udp"
    ports    = ["53"]
  }
}

data "google_compute_network" "wordpress_network" {
  name = "default"
}

resource "google_secret_manager_secret" "hestiacp_password" {
  secret_id = "hestiacp_password"
  replication {
    auto {}
  }
  version_destroy_ttl = "2592000s" # 30 days
}

resource "google_secret_manager_secret_version" "hestiacp_password" {
  secret     = google_secret_manager_secret.hestiacp_password.id
  depends_on = [google_secret_manager_secret.hestiacp_password]

  secret_data = random_password.hestiacp_password.result
}

resource "random_password" "hestiacp_password" {
  length  = 16
  special = true
  upper   = true
  lower   = true
}
