terraform {
  backend "gcs" {}
  required_version = "~>1.9"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "6.50.0"
    }
    namecheap = {
      source  = "namecheap/namecheap"
      version = "2.9.4"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.7.2"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "5.26.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
  zone    = "${var.region}-a"

  default_labels = {
    environment   = "prod"
    iac_repo_name = "gcp-site"
  }
}

provider "namecheap" {
  user_name   = var.namecheap_user
  api_user    = var.namecheap_user
  api_key     = var.namecheap_api_key
  use_sandbox = false
}

provider "cloudflare" {
  api_token = var.cloudflare_api_token
}
