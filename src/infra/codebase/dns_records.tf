data "cloudflare_zone" "site" {
  filter = {
    name    = var.website_domain
    account = { id = var.cloudflare_account_id }
  }
}

resource "namecheap_domain_records" "wordpress" {
  domain      = var.website_domain
  nameservers = sort(data.cloudflare_zone.site.name_servers)
  mode        = "OVERWRITE"

  lifecycle {
    prevent_destroy = true
  }
}

resource "cloudflare_dns_record" "tunnel" {
  for_each = toset([var.website_domain, "www.${var.website_domain}"])
  zone_id  = data.cloudflare_zone.site.zone_id
  name     = each.key
  type     = "CNAME"
  content  = "${cloudflare_zero_trust_tunnel_cloudflared.wordpress.id}.cfargotunnel.com"
  proxied  = true
  ttl      = 1
}

resource "cloudflare_dns_record" "dmarc" {
  zone_id = data.cloudflare_zone.site.zone_id
  name    = "_dmarc.${var.website_domain}"
  type    = "TXT"
  content = "\"v=DMARC1; p=reject; adkim=s; aspf=s\""
  ttl     = 1
}
