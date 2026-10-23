data "cloudflare_zero_trust_organization" "this" {
  account_id = var.cloudflare_account_id
}

resource "cloudflare_zero_trust_access_identity_provider" "otp" {
  account_id = var.cloudflare_account_id
  name       = "One-time PIN"
  type       = "onetimepin"
  config     = {}
}

resource "cloudflare_zero_trust_access_policy" "owner" {
  account_id = var.cloudflare_account_id
  name       = "owner"
  decision   = "allow"
  include    = [{ email = { email = var.admin_email } }]
}

resource "cloudflare_zero_trust_access_policy" "bypass" {
  account_id = var.cloudflare_account_id
  name       = "bypass"
  decision   = "bypass"
  include    = [{ everyone = {} }]
}

resource "cloudflare_zero_trust_access_application" "wp_admin" {
  account_id       = var.cloudflare_account_id
  name             = "wp-admin"
  type             = "self_hosted"
  session_duration = "24h"
  destinations     = [for p in ["wp-admin", "wp-admin/*", "wp-login.php", "wp-login.php/*"] : { type = "public", uri = "${var.website_domain}/${p}" }]
  policies         = [{ id = cloudflare_zero_trust_access_policy.owner.id, precedence = 1 }]
}

resource "cloudflare_zero_trust_access_application" "wp_ajax" {
  account_id   = var.cloudflare_account_id
  name         = "wp-admin-ajax"
  type         = "self_hosted"
  destinations = [{ type = "public", uri = "${var.website_domain}/wp-admin/admin-ajax.php" }]
  policies     = [{ id = cloudflare_zero_trust_access_policy.bypass.id, precedence = 1 }]
}
