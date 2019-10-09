//////////////////////////////////////////////
//    CloudFlare
//////////////////////////////////////////////
provider "cloudflare" {
  alias = "main"
  email = "${var.cf_email}"
  token = "${var.cf_token}"
}

provider "cloudflare" {
  alias = "srv"
  email = "${var.cf_srv_email}"
  token = "${var.cf_srv_token}"
}

/// DNS:
resource "cloudflare_record" "srv" {
  provider = "cloudflare.srv" 
  domain   = "${var.domain_srv}"
  name     = "${lower(var.name)}.srv"
  value    = "${var.server_ip}"
  type     = "A"
}

resource "cloudflare_zone" "this" {
  provider = "cloudflare.main" 
  count    = "${var.domain_is_sub ? "${var.cf_setting_override ? "1" : "0"}" : "${length(var.domain_list)}"}"
  zone     = "${var.domain_is_sub ? "${substr(var.domain_list[count.index],"${length(element(split(".",var.domain_list[count.index]),0)) + 1}",-1)}" : "${var.domain_list[count.index]}" }"
  plan     = "${var.cf_pro ? "pro" : "free"}"
}

resource "cloudflare_record" "this" {
  provider = "cloudflare.main" 
  count    = "${length(var.domain_list)}"
  domain   = "${var.domain_is_sub ? "${substr(var.domain_list[count.index],"${length(element(split(".",var.domain_list[count.index]),0)) + 1}",-1)}" : "${var.domain_list[count.index]}" }"
  name     = "${var.domain_is_sub ? "${element(split(".",var.domain_list[count.index]),0)}" : "@"}"
  value    = "${cloudflare_record.srv.hostname}"
  type     = "CNAME"
  proxied  = "${var.cf_proxied}"
  depends_on = ["cloudflare_zone.this"]
}

resource "cloudflare_record" "www" {
  provider = "cloudflare.main" 
  count    = "${var.domain_is_sub ? 0 : "${length(var.domain_list)}"}"
  domain   = "${var.domain_list[count.index]}"
  name     = "www"
  value    = "${cloudflare_record.srv.hostname}"
  type     = "CNAME"
  proxied  = true
  depends_on = ["cloudflare_zone.this"]
}

/// Setting:
resource "cloudflare_zone_settings_override" "this" {
  provider = "cloudflare.main" 
  count    = "${var.domain_is_sub ? "${var.cf_setting_override ? "1" : "0"}" : "${length(var.domain_list)}"}"
  name     = "${var.domain_is_sub ? "${substr(var.domain_list[count.index],"${length(element(split(".",var.domain_list[count.index]),0)) + 1}",-1)}" : "${var.domain_list[count.index]}" }"
  settings = ["${local.cf_setting_basic}"]
  depends_on = ["cloudflare_zone.this"]
}

resource "cloudflare_zone_settings_override" "pro" {
  provider = "cloudflare.main" 
  count    = "${var.cf_pro ? length(var.domain_list) : 0}"
  name     = "${var.domain_is_sub ? "${substr(var.domain_list[count.index],"${length(element(split(".",var.domain_list[count.index]),0)) + 1}",-1)}" : "${var.domain_list[count.index]}" }"
  settings = ["${var.cf_setting_pro}"]
  depends_on = ["cloudflare_zone.this"]
}

/// Page rules:
resource "cloudflare_page_rule" "free_1st" {
  provider = "cloudflare.main" 
  count    = "${length(var.cf_freerules) >= 1 ? "${length(var.domain_list)}" : 0 }"
  zone     = "${var.domain_is_sub ? "${substr(var.domain_list[count.index],"${length(element(split(".",var.domain_list[count.index]),0)) + 1}",-1)}" : "${var.domain_list[count.index]}" }"
  target   = "*${var.domain_list[count.index]}/${var.cf_freerules[0]}"
  priority = "${var.cf_page_rule_prio}"
  actions  = ["${var.cf_rule_action_cache}"]
  depends_on = ["cloudflare_zone.this"]
}

resource "cloudflare_page_rule" "free_2nd" {
  provider = "cloudflare.main" 
  count    = "${length(var.cf_freerules) >= 2 ? "${length(var.domain_list)}" : 0 }"
  zone     = "${var.domain_is_sub ? "${substr(var.domain_list[count.index],"${length(element(split(".",var.domain_list[count.index]),0)) + 1}",-1)}" : "${var.domain_list[count.index]}" }"
  target   = "*${var.domain_list[count.index]}/${var.cf_freerules[1]}"
  priority = "${var.cf_page_rule_prio - 1}"
  actions  = ["${var.cf_rule_action_cache}"]
  depends_on = ["cloudflare_zone.this"]
}

resource "cloudflare_page_rule" "free_3rd" {
  provider = "cloudflare.main" 
  count    = "${length(var.cf_freerules) >= 3 ? "${length(var.domain_list)}" : 0 }"
  zone     = "${var.domain_is_sub ? "${substr(var.domain_list[count.index],"${length(element(split(".",var.domain_list[count.index]),0)) + 1}",-1)}" : "${var.domain_list[count.index]}" }"
  target   = "*${var.domain_list[count.index]}/${var.cf_freerules[2]}"
  priority = "${var.cf_page_rule_prio - 2}"
  actions  = ["${var.cf_rule_action_cache}"]
  depends_on = ["cloudflare_zone.this"]
}

/// CF access rules:
resource "cloudflare_access_rule" "whitelist" {
  count    = "${var.whitelist_ip ? 1 : 0}"
  provider = "cloudflare.main" 
  notes    = "${var.group}-${var.name}"
  mode     = "whitelist"
  configuration {
    target = "ip"
    value  = "${var.server_ip}"
  }
}
