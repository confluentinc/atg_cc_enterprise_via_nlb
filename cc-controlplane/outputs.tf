output "resource-ids" {
  value = <<-EOT
  Environment ID:   ${confluent_environment.pe_staging.id}
  Kafka Cluster ID: ${confluent_kafka_cluster.enterprise.id}
  EOT

 sensitive = true
}

output "vpc_endpoint_service_name" {
  value = confluent_private_link_attachment.pla.aws[0].vpc_endpoint_service_name
}
output "dns_domain" {
  value = confluent_private_link_attachment.pla.dns_domain
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
output "plac" {
  value = confluent_private_link_attachment_connection.plac
}

output "am-cluster-admin" {
  value = confluent_role_binding.app-manager-kafka-cluster-admin
}
output "cc_environment" {
  value = confluent_environment.pe_staging
}

    
