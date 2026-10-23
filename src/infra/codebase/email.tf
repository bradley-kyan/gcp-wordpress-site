resource "cloudflare_email_routing_dns" "site" {
  zone_id = data.cloudflare_zone.site.zone_id
}

resource "cloudflare_email_routing_address" "owner" {
  account_id = var.cloudflare_account_id
  email      = var.owner_email
}

resource "cloudflare_email_routing_catch_all" "site" {
  zone_id    = data.cloudflare_zone.site.zone_id
  enabled    = true
  matchers   = [{ type = "all" }]
  actions    = [{ type = "forward", value = [cloudflare_email_routing_address.owner.email] }]
  depends_on = [cloudflare_email_routing_dns.site]
}
