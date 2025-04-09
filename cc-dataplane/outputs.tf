output "resource-ids" {
  value = <<-EOT
  
  Kafka topic name: ${confluent_kafka_topic.orders.topic_name}
  

  Service Accounts and their Kafka API Keys (API Keys inherit the permissions granted to the owner):
  ${var.app-manager-sa.display_name}:                     ${var.app-manager-sa.id}
  ${var.app-manager-sa.display_name}'s Kafka API Key:     "${confluent_api_key.app-manager-kafka-api-key.id}"
  ${var.app-manager-sa.display_name}'s Kafka API Secret:  "${confluent_api_key.app-manager-kafka-api-key.secret}"

  ${var.app-producer-sa.display_name}:                    ${var.app-producer-sa.id}
  ${var.app-producer-sa.display_name}'s Kafka API Key:    "${confluent_api_key.app-producer-kafka-api-key.id}"
  ${var.app-producer-sa.display_name}'s Kafka API Secret: "${confluent_api_key.app-producer-kafka-api-key.secret}"

  ${var.app-consumer-sa.display_name}:                    ${var.app-consumer-sa.id}
  ${var.app-consumer-sa.display_name}'s Kafka API Key:    "${confluent_api_key.app-consumer-kafka-api-key.id}"
  ${var.app-consumer-sa.display_name}'s Kafka API Secret: "${confluent_api_key.app-consumer-kafka-api-key.secret}"

  In order to use the Confluent CLI v2 to produce and consume messages from topic '${confluent_kafka_topic.orders.topic_name}' using Kafka API Keys
  of ${var.app-producer-sa.display_name} and ${var.app-consumer-sa.display_name} service accounts
  run the following commands:

  # 1. Log in to Confluent Cloud
  $ confluent login

  # 2. Produce key-value records to topic '${confluent_kafka_topic.orders.topic_name}' by using ${var.app-producer-sa.display_name}'s Kafka API Key
  $ confluent kafka topic produce ${confluent_kafka_topic.orders.topic_name} --environment ${var.cc-environment.id} --cluster ${var.kafka-cluster.id} --api-key "${confluent_api_key.app-producer-kafka-api-key.id}" --api-secret "${confluent_api_key.app-producer-kafka-api-key.secret}"
  # Enter a few records and then press 'Ctrl-C' when you're done.
  # Sample records:
  # {"number":1,"date":18500,"shipping_address":"899 W Evelyn Ave, Mountain View, CA 94041, USA","cost":15.00}
  # {"number":2,"date":18501,"shipping_address":"1 Bedford St, London WC2E 9HG, United Kingdom","cost":5.00}
  # {"number":3,"date":18502,"shipping_address":"3307 Northland Dr Suite 400, Austin, TX 78731, USA","cost":10.00}

  # 3. Consume records from topic '${confluent_kafka_topic.orders.topic_name}' by using ${var.app-consumer-sa.display_name}'s Kafka API Key
  $ confluent kafka topic consume ${confluent_kafka_topic.orders.topic_name} --from-beginning --environment ${var.cc-environment.id} --cluster ${var.kafka-cluster.id} --api-key "${confluent_api_key.app-consumer-kafka-api-key.id}" --api-secret "${confluent_api_key.app-consumer-kafka-api-key.secret}"
  # When you are done, press 'Ctrl-C'.
  EOT
}
