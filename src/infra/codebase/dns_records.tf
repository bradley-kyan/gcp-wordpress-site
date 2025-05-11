resource "namecheap_domain_records" "wordpress" {
  domain = var.website_domain
  nameservers = ["ns1.${var.website_domain}", "ns2.${var.website_domain}"]

  mode = "OVERWRITE"
}
