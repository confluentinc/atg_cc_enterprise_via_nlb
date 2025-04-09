/*
variable "confluent_cloud_api_key" {
  description = "Confluent Cloud API Key (also referred as Cloud API ID)."
  type        = string
}

variable "confluent_cloud_api_secret" {
  description = "Confluent Cloud API Secret."
  type        = string
  sensitive   = true
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



