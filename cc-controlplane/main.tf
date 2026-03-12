terraform {
  required_providers {
    confluent = {
      source  = "confluentinc/confluent"
      version = ">=2.50.0"
    }
  }
}
resource "random_id" "env_display_id" {
    byte_length = 4
}

resource "confluent_environment" "pe_staging" {
  display_name = "${var.env_prefix}-environment-${random_id.env_display_id.hex}"
}

resource "confluent_kafka_cluster" "enterprise" {
  display_name = "inventory"
  availability = "LOW"
  cloud        = "AWS"
  region       = var.region
  enterprise {}
  environment {
    id = confluent_environment.pe_staging.id
  }
}

# PLATT mode resources
resource "confluent_private_link_attachment" "pla" {
  count        = var.privatelink_mode == "platt" ? 1 : 0
  cloud        = "AWS"
  region       = var.region
  display_name = "staging-aws-platt"
  environment {
    id = confluent_environment.pe_staging.id
  }
}

# PLATT connection moved to main.tf to break circular dependency
# Gateway access point also moved to main.tf to break circular dependency

# Gateway mode resources
resource "confluent_gateway" "main" {
  count        = var.privatelink_mode == "gateway" ? 1 : 0
  display_name = "${var.env_prefix}-gateway"
  environment {
    id = confluent_environment.pe_staging.id
  }

  aws_ingress_private_link_gateway {
    region = var.region
  }
}

resource "confluent_service_account" "pe_app-manager" {
  display_name = "pe_app-manager"
  description  = "Service account to manage 'inventory' Kafka cluster"
}

resource "confluent_role_binding" "app-manager-kafka-cluster-admin" {
  principal   = "User:${confluent_service_account.pe_app-manager.id}"
  role_name   = "CloudClusterAdmin"
  crn_pattern = confluent_kafka_cluster.enterprise.rbac_crn
}

resource "confluent_service_account" "pe_app-consumer" {
  display_name = "pe_app-consumer"
  description  = "Service account to consume from 'orders' topic of 'inventory' Kafka cluster"
}

resource "confluent_service_account" "pe_app-producer" {
  display_name = "pe_app-producer"
  description  = "Service account to produce to 'orders' topic of 'inventory' Kafka cluster"
}