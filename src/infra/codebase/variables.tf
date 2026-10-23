variable "project_id" {
  description = "The ID of the project in which the resources will be created."
  type        = string
}

variable "region" {
  description = "The region in which the resources will be created."
  type        = string
  default     = "us-west1"
}

variable "namecheap_user" {
  description = "The Namecheap username."
  type        = string
}

variable "namecheap_api_key" {
  description = "The Namecheap API key."
  type        = string
  sensitive   = true
}

variable "website_domain" {
  description = "The domain name for the website."
  type        = string
}

variable "cloudflare_api_token" {
  description = "Cloudflare API token."
  type        = string
  sensitive   = true
}

variable "cloudflare_account_id" {
  description = "Cloudflare account ID owning the zone."
  type        = string
}

variable "owner_email" {
  description = "Only address allowed through Cloudflare Access; destination for forwarded mail."
  type        = string
}
