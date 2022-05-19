variable "cdn_id" {
  description = "Cloudfront Id"
  default     = "E3554BHOW3RXY2"
}

variable "cdn_path" {
  description = "Cloudfront Behavior Path for the Load Balancer"
  default     = "crm-fe-prod"
}

variable "lb_url" {
  description = "Load Balancer Url"
  default     = "aac5e1e3235cc4c028de730c26369163-d8052e4acdbbae74.elb.us-east-1.amazonaws.com"
}

