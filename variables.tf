variable "region" {
  description = "The AWS region in which to create the VPCs and CC cluster"
  type        = string
  default     = "eu-west-1"
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

variable "privatelink_mode" {
  description = "PrivateLink mode: 'platt' for Private Link Attachment or 'gateway' for Gateway + Access Point"
  type        = string
  default     = "platt"
  validation {
    condition     = contains(["platt", "gateway"], var.privatelink_mode)
    error_message = "privatelink_mode must be either 'platt' or 'gateway'."
  }
}
