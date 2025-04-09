terraform {
  required_providers {
    confluent = {
      source  = "confluentinc/confluent"
      version = ">=2.20.0"
    }
  }
}

resource "confluent_api_key" "app-manager-kafka-api-key" {
  display_name = "app-manager-kafka-api-key"
  description  = "Kafka API Key that is owned by 'app-manager' service account"
  owner {
    id          = var.app-manager-sa.id
    api_version = var.app-manager-sa.api_version
    kind        = var.app-manager-sa.kind
  }

  managed_resource {
    id          = var.kafka-cluster.id
    api_version = var.kafka-cluster.api_version
    kind        = var.kafka-cluster.kind

    environment {
      id = var.cc-environment.id
    }
  }

  # The goal is to ensure that confluent_role_binding.app-manager-kafka-cluster-admin is created before
  # confluent_api_key.app-manager-kafka-api-key is used to create instances of
  # confluent_kafka_topic, confluent_kafka_acl resources.

  # 'depends_on' meta-argument is specified in confluent_api_key.app-manager-kafka-api-key to avoid having
  # multiple copies of this definition in the configuration which would happen if we specify it in
  # confluent_kafka_topic, confluent_kafka_acl resources instead.
  depends_on = [
    var.app-manager-is-cluster-admin, var.plac
  ]
}

resource "confluent_kafka_topic" "orders" {
  kafka_cluster {
    id = var.kafka-cluster.id
  }
  topic_name    = "orders"
  rest_endpoint = var.kafka-cluster.rest_endpoint
  credentials {
    key    = confluent_api_key.app-manager-kafka-api-key.id
    secret = confluent_api_key.app-manager-kafka-api-key.secret
  }
}

resource "confluent_api_key" "app-consumer-kafka-api-key" {
  display_name = "app-consumer-kafka-api-key"
  description  = "Kafka API Key that is owned by 'pe_app-consumer' service account"
  owner {
    id          = var.app-consumer-sa.id
    api_version = var.app-consumer-sa.api_version
    kind        = var.app-consumer-sa.kind
  }

  managed_resource {
    id          = var.kafka-cluster.id
    api_version = var.kafka-cluster.api_version
    kind        = var.kafka-cluster.kind

    environment {
      id = var.cc-environment.id
    }
  }
}

resource "confluent_kafka_acl" "app-producer-write-on-topic" {
  kafka_cluster {
    id = var.kafka-cluster.id
  }
  resource_type = "TOPIC"
  resource_name = confluent_kafka_topic.orders.topic_name
  pattern_type  = "LITERAL"
  principal     = "User:${var.app-producer-sa.id}"
  host          = "*"
  operation     = "WRITE"
  permission    = "ALLOW"
  rest_endpoint = var.kafka-cluster.rest_endpoint
  credentials {
    key    = confluent_api_key.app-manager-kafka-api-key.id
    secret = confluent_api_key.app-manager-kafka-api-key.secret
  }
}

resource "confluent_api_key" "app-producer-kafka-api-key" {
  display_name = "app-producer-kafka-api-key"
  description  = "Kafka API Key that is owned by 'pe_app-producer' service account"
  owner {
    id          = var.app-producer-sa.id
    api_version = var.app-producer-sa.api_version
    kind        = var.app-producer-sa.kind
  }

  managed_resource {
    id          = var.kafka-cluster.id
    api_version = var.kafka-cluster.api_version
    kind        = var.kafka-cluster.kind

    environment {
      id = var.cc-environment.id
    }
  }
}

// Note that in order to consume from a topic, the principal of the consumer ('pe_app-consumer' service account)
// needs to be authorized to perform 'READ' operation on both Topic and Group resources:
// confluent_kafka_acl.app-consumer-read-on-topic, confluent_kafka_acl.app-consumer-read-on-group.
// https://docs.confluent.io/platform/current/kafka/authorization.html#using-acls

resource "confluent_kafka_acl" "app-consumer-read-on-topic" {
  kafka_cluster {
    id = var.kafka-cluster.id
  }
  resource_type = "TOPIC"
  resource_name = confluent_kafka_topic.orders.topic_name
  pattern_type  = "LITERAL"
  principal     = "User:${var.app-consumer-sa.id}"
  host          = "*"
  operation     = "READ"
  permission    = "ALLOW"
  rest_endpoint = var.kafka-cluster.rest_endpoint
  credentials {
    key    = confluent_api_key.app-manager-kafka-api-key.id
    secret = confluent_api_key.app-manager-kafka-api-key.secret
  }
}

resource "confluent_kafka_acl" "app-consumer-read-on-group" {
  kafka_cluster {
    id = var.kafka-cluster.id
  }
  resource_type = "GROUP"
  // The existing values of resource_name, pattern_type attributes are set up to match Confluent CLI's default consumer group ID ("confluent_cli_consumer_<uuid>").
  // https://docs.confluent.io/confluent-cli/current/command-reference/kafka/topic/confluent_kafka_topic_consume.html
  // Update the values of resource_name, pattern_type attributes to match your target consumer group ID.
  // https://docs.confluent.io/platform/current/kafka/authorization.html#prefixed-acls
  resource_name = "confluent_cli_consumer_"
  pattern_type  = "PREFIXED"
  principal     = "User:${var.app-consumer-sa.id}"
  host          = "*"
  operation     = "READ"
  permission    = "ALLOW"
  rest_endpoint = var.kafka-cluster.rest_endpoint
  credentials {
    key    = confluent_api_key.app-manager-kafka-api-key.id
    secret = confluent_api_key.app-manager-kafka-api-key.secret
  }
}

