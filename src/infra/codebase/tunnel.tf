resource "cloudflare_zero_trust_tunnel_cloudflared" "wordpress" {
  account_id = var.cloudflare_account_id
  name       = "wordpress"
  config_src = "cloudflare"
}

data "cloudflare_zero_trust_tunnel_cloudflared_token" "wordpress" {
  account_id = var.cloudflare_account_id
  tunnel_id  = cloudflare_zero_trust_tunnel_cloudflared.wordpress.id
}

locals {
  origin = "http://wordpress:80"
  team   = trimsuffix(data.cloudflare_zero_trust_organization.this.auth_domain, ".cloudflareaccess.com")
}

resource "cloudflare_zero_trust_tunnel_cloudflared_config" "wordpress" {
  account_id = var.cloudflare_account_id
  tunnel_id  = cloudflare_zero_trust_tunnel_cloudflared.wordpress.id

  config = {
    ingress = [
      {
        hostname = var.website_domain
        path     = "^/wp-admin/admin-ajax\\.php$"
        service  = local.origin
      },
      {
        hostname = var.website_domain
        path     = "^/(wp-admin|wp-login\\.php)"
        service  = local.origin
        origin_request = {
          access = {
            required  = true
            team_name = local.team
            aud_tag   = [cloudflare_zero_trust_access_application.wp_admin.aud]
          }
        }
      },
      {
        hostname = var.website_domain
        service  = local.origin
      },
      {
        service = "http_status:404"
      },
    ]
  }
}
