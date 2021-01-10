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

variable "s3_website_index_document" {
  type = string
  default = null
  description = "(Required unless using `s3_website_redirect_all_requests_to`) Index document name. For more info, visit https://docs.aws.amazon.com/AmazonS3/latest/dev/IndexDocumentSupport.html"
}

variable "s3_website_error_document" {
  type = string
  default = null
  description = "(Optional) Custom error document name. For more info, visit https://docs.aws.amazon.com/AmazonS3/latest/dev/CustomErrorDocSupport.html"
}

variable "s3_website_redirect_all_requests_to" {
  type = string
  default = null
  description = "(Optional) A hostname to redirect all website requests for this domain. For more info, visit https://docs.aws.amazon.com/AmazonS3/latest/dev/how-to-page-redirect.html#redirect-endpoint-host"
}

variable "s3_website_routing_rules" {
  type = string
  default = null
  description = "(Optional) A JSON array describing [Routing rules](https://docs.aws.amazon.com/AmazonS3/latest/dev/how-to-page-redirect.html#advanced-conditional-redirects)"
}
