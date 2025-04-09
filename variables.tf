variable "region" {
  description = "The AWS region in which to create the VPCs and CC cluster"
  type        = string
}
variable "owner" {
  description = "The email address of the person creating the resources"
  type        = string
}

variable "confluent_cloud_api_key" {
  description = "Confluent Cloud API Key (also referred as Cloud API ID)."
  type        = string
}

variable "confluent_cloud_api_secret" {
  description = "Confluent Cloud API Secret."
  type        = string
  sensitive   = true
}
variable "env_prefix" {
  description = "String to prefix names with"
  type        = string
  default     = "e2"
}
