terraform {
  required_providers {
    confluent = {
      source  = "confluentinc/confluent"
      version = ">=2.20.0"
    }
  }
}
resource "random_id" "env_display_id" {
    byte_length = 4
}

provider "confluent" {
  cloud_api_key    = var.confluent_cloud_api_key
  cloud_api_secret = var.confluent_cloud_api_secret
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

resource "confluent_private_link_attachment" "pla" {
  cloud = "AWS"
  region = var.region
  display_name = "staging-aws-platt"
  environment {
    id = confluent_environment.pe_staging.id
  }
}

resource "confluent_private_link_attachment_connection" "plac" {
  display_name = "staging-aws-plattc"
  environment {
    id = confluent_environment.pe_staging.id
  }
  aws {
    vpc_endpoint_id = var.vpc_endpoint_id
  }

  private_link_attachment {
    id = confluent_private_link_attachment.pla.id
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