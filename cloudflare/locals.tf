locals {
  cf_setting_basic = {
    // Crypto:
    always_use_https  = "${var.cf_always_https}"
    ssl               = "flexible"
    // Firewall:
    security_level    = "high"
    challenge_ttl     = "1800"
    // Caching:
    browser_cache_ttl = "0"
    always_online     = "on"

    // Speed:
    brotli            = "on"
    minify            = "${list(
      map("css","on",
        "js","on",
        "html","on"
      )
    )}"
  }
}
