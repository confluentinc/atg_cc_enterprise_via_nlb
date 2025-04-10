variable "region" {
  description = "The AWS region in which to create the VPCs"
  type        = string
}
variable "owner" {
  description = "The email address of the person creating the resources"
  type        = string
}
/*
variable "security_group_id" {
  description = "List of security groups to use for instance"
  type        = string
}*/
variable "subnet_id" {
  description = "Subnet to place the instance in"
  type        = string
}
variable "vpc_id" {
  description = "The ID of the VPC in which the jumphost will be created."
  type        = string
}
variable "env_prefix" {
  description = "String to prefix names with"
  type        = string
}

