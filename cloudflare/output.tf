output "srv_hostname" {
  value = "${cloudflare_record.srv.hostname}"
}

output "cf_zone_ids" {
  value = "${cloudflare_zone.this.*.id}"
}

