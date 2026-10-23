resource "google_compute_network" "wordpress" {
  name                    = "wordpress"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "wordpress" {
  name          = "wordpress-${var.region}"
  network       = google_compute_network.wordpress.id
  region        = var.region
  ip_cidr_range = "10.10.0.0/24"
}

resource "google_compute_firewall" "iap_ssh" {
  name          = "allow-iap-ssh"
  network       = google_compute_network.wordpress.id
  direction     = "INGRESS"
  source_ranges = ["35.235.240.0/20"]
  target_tags   = ["wordpress"]

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
}

resource "google_project_service" "iap" {
  service            = "iap.googleapis.com"
  disable_on_destroy = false
}
