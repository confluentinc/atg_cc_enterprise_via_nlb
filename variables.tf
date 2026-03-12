variable "region" {
  description = "The AWS region in which to create the VPCs and CC cluster"
  type        = string
  default     = "eu-west-1"
}
variable "owner" {
  description = "The email address of the person creating the resources"
  type        = string
}

variable "env_prefix" {
  description = "String to prefix names with"
  type        = string
  default     = "e2"
}

variable "privatelink_mode" {
  description = "PrivateLink mode: 'platt' for Private Link Attachment or 'gateway' for Gateway + Access Point"
  type        = string
  default     = "gateway"
  validation {
    condition     = contains(["platt", "gateway"], var.privatelink_mode)
    error_message = "privatelink_mode must be either 'platt' or 'gateway'."
  }
}

variable "enable_dataplane" {
  description = "Enable dataplane module (API keys and topics). Set to true after initial apply when DNS is configured."
  type        = bool
  default     = false
}
