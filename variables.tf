variable "cloudflare_zone_id" {
  type = string
  description = "(Required) Cloudflare zone ID to create DNS record"
}

variable "cloudflare_zone_name" {
  type = string
  description = "(Required) Cloudflare zone name to create DNS record"
}

variable "cloudflare_record_name" {
  type = string
  description = "(Required) DNS record name for the website"
}

variable "cloudfront_default_root_object" {
  type = string
  default = null
}

variable "cloudfront_404_error_resource" {
  type = string
  default = null
}
