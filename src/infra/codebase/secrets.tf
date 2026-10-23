resource "random_password" "mariadb_root" {
  length  = 32
  special = false
}

resource "random_password" "wordpress_db" {
  length  = 32
  special = false
}

locals {
  vm_secrets = {
    mariadb-root-password = random_password.mariadb_root.result
    wordpress-db-password = random_password.wordpress_db.result
    cloudflared-token     = data.cloudflare_zero_trust_tunnel_cloudflared_token.wordpress.token
  }
}

resource "google_secret_manager_secret" "vm" {
  for_each  = toset(["mariadb-root-password", "wordpress-db-password", "cloudflared-token"])
  secret_id = each.key

  replication {
    user_managed {
      replicas {
        location = var.region
      }
    }
  }
}

resource "google_secret_manager_secret_version" "vm" {
  for_each    = google_secret_manager_secret.vm
  secret      = each.value.id
  secret_data = local.vm_secrets[each.key]
}

resource "google_secret_manager_secret_iam_member" "vm" {
  for_each  = google_secret_manager_secret.vm
  secret_id = each.value.id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.vm.email}"
}
