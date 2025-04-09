variable "confluent_cloud_api_key" {
  description = "Confluent Cloud API Key (also referred as Cloud API ID)."
  type        = string
}

variable "confluent_cloud_api_secret" {
  description = "Confluent Cloud API Secret."
  type        = string
  sensitive   = true
}

/*
variable "aws_account_id" {
  description = "The AWS Account ID (12 digits)"
  type        = string
}
*/

/*
variable "vpc_id" {
  description = "The ID of the VPC in which the endpoint will be used."
  type        = string
}
*/
/*
variable "region" {
  description = "The region of the AWS peer VPC."
  type        = string
}
variable "vpc_endpoint_id" {
  description = "The VPC where the PL endpoints live"
  type        = string
}
*/

/*
variable "subnets_to_privatelink" {
  description = "A map of Zone ID to Subnet ID (i.e.: {\"use1-az1\" = \"subnet-abcdef0123456789a\", ...})"
  type        = map(string)
}
*/

variable "app-manager-sa" {
  description = "The app manager service account"
}
variable "app-consumer-sa" {
  description = "The app consumer service account"
}
variable "app-producer-sa" {
  description = "The app producer service account"
}
variable "app-manager-is-cluster-admin" {
  description = "The app manager role binding to as cluster admin"
}
variable "plac" {
  description = "The private network connection is ready"
}
variable "kafka-cluster" {
  description = "The Kakfa Cluster resource"
}

variable "cc-environment" {
  description = "The Confluent Cloud Environment"
}
variable "env_prefix" {
  description = "String to prefix names with"
  type        = string
}



