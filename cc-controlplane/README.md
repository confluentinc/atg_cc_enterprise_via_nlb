# Confluent Cloud Control Plane Module

Creates an Enterprise cluster called "inventory" with supporting resources.

## Features

- Supports both PrivateLink architectures:
  - **Gateway + Access Point mode** (default): Uses `confluent_gateway` with AWS Ingress Private Link Gateway
  - **PLATT mode**: Uses `confluent_private_link_attachment`
- Creates Confluent environment and Kafka cluster
- Sets up service accounts for cluster management, producing, and consuming
- Configures RBAC role bindings

## Mode Selection

Set the `privatelink_mode` variable:
- `"gateway"` - Gateway + Access Point architecture (default, requires Confluent provider >= 2.50.0)
- `"platt"` - Private Link Attachment architecture

## Outputs

- `vpc_endpoint_service_name` - VPC Endpoint Service Name to create AWS VPC endpoint (both modes)
- `dns_domain` - DNS domain for private hosted zone (PLATT mode only)
- `gateway` - Gateway resource (gateway mode only)
- `pla` - Private Link Attachment resource (PLATT mode only)
- Service account and cluster outputs

**Note**: In gateway mode, the `confluent_access_point` resource is created in the root main.tf to avoid circular dependencies.

This is based on the examples in the Confluent Terraform provider, in particular examples/configurations/enterprise-privatelinkattachment-aws-kafka-acls