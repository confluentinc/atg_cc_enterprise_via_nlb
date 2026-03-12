output "resource-ids" {
  value = <<-EOT
  Environment ID:   ${confluent_environment.pe_staging.id}
  Kafka Cluster ID: ${confluent_kafka_cluster.enterprise.id}
  EOT

 sensitive = true
}

output "vpc_endpoint_service_name" {
  value = var.privatelink_mode == "platt" ? confluent_private_link_attachment.pla[0].aws[0].vpc_endpoint_service_name : confluent_gateway.main[0].aws_ingress_private_link_gateway[0].vpc_endpoint_service_name
}

output "dns_domain" {
  value = var.privatelink_mode == "platt" ? confluent_private_link_attachment.pla[0].dns_domain : ""
  description = "DNS domain for PLATT mode. For gateway mode, use confluent_access_point.gateway output from main.tf"
}

output "app-manager" {
  value = confluent_service_account.pe_app-manager
}
output "app-consumer" {
  value = confluent_service_account.pe_app-consumer
}
output "app-producer" {
  value = confluent_service_account.pe_app-producer
}

output "enterprise_cluster" {
  value = confluent_kafka_cluster.enterprise
}

output "pla" {
  value = var.privatelink_mode == "platt" ? confluent_private_link_attachment.pla[0] : null
}

output "gateway" {
  value = var.privatelink_mode == "gateway" ? confluent_gateway.main[0] : null
}

output "am-cluster-admin" {
  value = confluent_role_binding.app-manager-kafka-cluster-admin
}
output "cc_environment" {
  value = confluent_environment.pe_staging
}

    
