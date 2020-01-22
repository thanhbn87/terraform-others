output "cf_zone_ids" {
  value = "${cloudflare_zone.this.*.id}"
}

