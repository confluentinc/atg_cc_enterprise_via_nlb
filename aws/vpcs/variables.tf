variable "region" {
  description = "The AWS region in which to create the VPCs"
  type        = string
}
variable "environment" {
  default = "expose_enterprise_public"
}
variable "owner" {
  description = "The email address of the person creating the resources"
  type        = string
}
variable "env_prefix" {
  description = "String to prefix names with"
  type        = string
}


variable "vpc_cidr" {
  default     = "10.0.0.0/16"
  description = "CIDR block of the vpc"
}

variable "public_subnets_cidr" {
  type        = list(any)
  //default     = ["10.0.0.0/24", "10.0.128.0/20"]
  default     = ["10.0.1.0/24"]
  description = "CIDR block for Public Subnet"
}

variable "private_subnets_cidr" {
  type        = list(any)
  //default     = ["10.0.16.0/20", "10.0.144.0/20"]
  default     = ["10.0.2.0/24"]
  description = "CIDR block for Private Subnet"
}

variable "pl_endpoints" {
  type = list (any)
  description = "List of ids for the PL endpoints"
}