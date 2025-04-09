terraform {
  required_version = ">= 0.14.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.17.0"
    }
    confluent = {
      source  = "confluentinc/confluent"
      version = ">=2.20.0"
    }
  }
}


provider "aws" {
  region = var.region
}

module "awsvpcs" {
  source        = "./aws/vpcs"
  region        = var.region
  owner         = var.owner
  pl_endpoints  = [module.privatelink.vpc_endpoint]
  env_prefix    = var.env_prefix
}
module "jumphost" {
  source                = "./aws/jump-host"
  region                = var.region
  subnet_id             = module.awsvpcs.public_subnet_id
  vpc_id                = module.awsvpcs.vpc_id
  owner                 = var.owner
  env_prefix            = var.env_prefix
}

module "privatelink" {
  source                   = "./aws/privatelink-endpoint"
  vpc_id                   = module.awsvpcs.vpc_id
  privatelink_service_name = module.cc_controlplane.vpc_endpoint_service_name
  dns_domain               = module.cc_controlplane.dns_domain
  subnets_to_privatelink   = {"euw1-az1" = module.awsvpcs.private_subnet_id}
  subnets_list             = [module.awsvpcs.private_subnet_id]
  owner                    = var.owner
  env_prefix               = var.env_prefix
  nlb_security_group        = module.awsvpcs.loadbalancer_sg
}

module "cc_controlplane" {
  source                   = "./cc-controlplane"
  vpc_id                   = module.awsvpcs.vpc_id

  confluent_cloud_api_key  = var.confluent_cloud_api_key
  confluent_cloud_api_secret = var.confluent_cloud_api_secret
  region                    = var.region
  vpc_endpoint_id          = module.privatelink.vpc_endpoint_id
  owner                    = var.owner 
  env_prefix               = var.env_prefix
}
output "endpoint_info" {
  value = <<-EOT
  In order to be able to access the dataplane you need to add
  an entry to your local /etc/hosts file to map
  Public IP address of cluster:   ${module.awsvpcs.loadbalancer_ip.public_ip}
  FQDN of cluster: ${split(":", module.cc_controlplane.enterprise_cluster.bootstrap_endpoint)[0]}

  EOT

  sensitive = true
}

data "external" "check_dataplane_access" {
  program     = ["/bin/bash", "-c", "${path.module}/check_dataplane.sh", "${module.cc_controlplane.enterprise_cluster.bootstrap_endpoint}", "9092"]
}

module "cc_dataplane" {
  source                   = "./cc-dataplane"

  # Don't attempt any DataPlane API calls if we can't access it yet
  count                    = data.external.check_dataplane_access.result.is_connected == "true" ? 1 : 0

  confluent_cloud_api_key  = var.confluent_cloud_api_key
  confluent_cloud_api_secret = var.confluent_cloud_api_secret

  app-manager-sa           = module.cc_controlplane.app-manager
  app-consumer-sa          = module.cc_controlplane.app-consumer
  app-producer-sa          = module.cc_controlplane.app-producer
  kafka-cluster            = module.cc_controlplane.enterprise_cluster
  plac                     = module.cc_controlplane.plac
  app-manager-is-cluster-admin = module.cc_controlplane.am-cluster-admin
  cc-environment           = module.cc_controlplane.cc_environment
  //owner                    = var.owner 
  env_prefix               = var.env_prefix
}

output "connection_info" {
  value = [
    for v in module.cc_dataplane: v.resource-ids
  ]
  /*
  value = <<-EOT
  ${module.cc_dataplane[*].resource-ids}
  EOT
  */

  sensitive = true
}


