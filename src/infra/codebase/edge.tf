resource "cloudflare_zone_setting" "site" {
  for_each   = { ssl = "strict", always_use_https = "on", min_tls_version = "1.2" }
  zone_id    = data.cloudflare_zone.site.zone_id
  setting_id = each.key
  value      = each.value
}

resource "cloudflare_ruleset" "firewall" {
  zone_id = data.cloudflare_zone.site.zone_id
  name    = "default"
  kind    = "zone"
  phase   = "http_request_firewall_custom"
  rules = [{
    description = "Block xmlrpc"
    expression  = "http.request.uri.path contains \"/xmlrpc.php\""
    action      = "block"
  }]
}

resource "cloudflare_ruleset" "redirect" {
  zone_id = data.cloudflare_zone.site.zone_id
  name    = "default"
  kind    = "zone"
  phase   = "http_request_dynamic_redirect"
  rules = [{
    description = "www to apex"
    expression  = "http.host eq \"www.${var.website_domain}\""
    action      = "redirect"
    action_parameters = {
      from_value = {
        status_code           = 301
        preserve_query_string = true
        target_url = {
          expression = "concat(\"https://${var.website_domain}\", http.request.uri.path)"
        }
      }
    }
  }]
}
