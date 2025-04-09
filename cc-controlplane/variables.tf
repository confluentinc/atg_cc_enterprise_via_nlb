variable "vpc_id" {
  description = "The ID of the VPC in which the endpoint will be used."
  type        = string
}

variable "region" {
  description = "The region of the AWS peer VPC."
  type        = string
}
variable "vpc_endpoint_id" {
  description = "The VPC where the PL endpoints live"
  type        = string
}

variable "owner" {
  description = "The email address of the person creating the resources"
  type        = string
}
variable "env_prefix" {
  description = "String to prefix names with"
  type        = string
}

