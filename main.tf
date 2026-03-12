terraform {
  required_version = ">= 0.14.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.17.0"
    }
    confluent = {
      source  = "confluentinc/confluent"
      version = ">=2.50.0"
    }
  }
}


provider "aws" {
  region = var.region
}

provider "confluent" {
  # Uses CONFLUENT_CLOUD_API_KEY and CONFLUENT_CLOUD_API_SECRET environment variables
}

module "awsvpcs" {
  source       = "./aws/vpcs"
  region       = var.region
  owner        = var.owner
  pl_endpoints = []  # Target attachments created separately below
  env_prefix   = var.env_prefix
}
module "jumphost" {
  source                = "./aws/jump-host"
  region                = var.region
  subnet_id             = module.awsvpcs.public_subnet_id
  vpc_id                = module.awsvpcs.vpc_id
  owner                 = var.owner
  env_prefix            = var.env_prefix
}

# PLATT mode: privatelink module (creates VPC endpoint using attachment service name)
module "privatelink" {
  count                    = var.privatelink_mode == "platt" ? 1 : 0
  source                   = "./aws/privatelink-endpoint"
  vpc_id                   = module.awsvpcs.vpc_id
  privatelink_service_name = module.cc_controlplane.vpc_endpoint_service_name
  dns_domain               = module.cc_controlplane.dns_domain
  subnets_to_privatelink   = {(module.awsvpcs.private_subnet_az_id) = module.awsvpcs.private_subnet_id}
  subnets_list             = [module.awsvpcs.private_subnet_id]
  owner                    = var.owner
  env_prefix               = var.env_prefix
  nlb_security_group       = module.awsvpcs.loadbalancer_sg
}

# PLATT mode: create connection after VPC endpoint exists
resource "confluent_private_link_attachment_connection" "plac" {
  count        = var.privatelink_mode == "platt" ? 1 : 0
  display_name = "staging-aws-plattc"
  environment {
    id = module.cc_controlplane.cc_environment.id
  }
  aws {
    vpc_endpoint_id = module.privatelink[0].vpc_endpoint_id
  }
  private_link_attachment {
    id = module.cc_controlplane.pla.id
  }
}

# Gateway mode: create VPC endpoint directly
resource "aws_security_group" "gateway_privatelink" {
  count       = var.privatelink_mode == "gateway" ? 1 : 0
  name        = "ccloud-gateway-privatelink_${var.env_prefix}_${module.awsvpcs.vpc_id}"
  description = "Confluent Cloud Gateway PrivateLink security group for ${var.env_prefix} in ${module.awsvpcs.vpc_id}"
  vpc_id      = module.awsvpcs.vpc_id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  ingress {
    from_port   = 9092
    to_port     = 9092
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_vpc_endpoint" "gateway_privatelink" {
  count               = var.privatelink_mode == "gateway" ? 1 : 0
  vpc_id              = module.awsvpcs.vpc_id
  service_name        = module.cc_controlplane.vpc_endpoint_service_name
  vpc_endpoint_type   = "Interface"
  security_group_ids  = [aws_security_group.gateway_privatelink[0].id]
  subnet_ids          = [module.awsvpcs.private_subnet_id]
  private_dns_enabled = false

  tags = {
    owner = var.owner
    Name  = "${var.env_prefix}-gateway-privatelink-endpoint"
  }
}

# Gateway mode: access point (created after VPC endpoint)
resource "confluent_access_point" "gateway" {
  count        = var.privatelink_mode == "gateway" ? 1 : 0
  display_name = "${var.env_prefix}-access-point"
  environment {
    id = module.cc_controlplane.cc_environment.id
  }
  gateway {
    id = module.cc_controlplane.gateway.id
  }

  aws_ingress_private_link_endpoint {
    vpc_endpoint_id = aws_vpc_endpoint.gateway_privatelink[0].id
  }
}

module "cc_controlplane" {
  source           = "./cc-controlplane"
  vpc_id           = module.awsvpcs.vpc_id
  region           = var.region
  owner            = var.owner
  env_prefix       = var.env_prefix
  privatelink_mode = var.privatelink_mode
}

# Gateway mode: Route53 zone using dns_domain from access_point
resource "aws_route53_zone" "gateway_privatelink" {
  count = var.privatelink_mode == "gateway" ? 1 : 0
  name  = confluent_access_point.gateway[0].aws_ingress_private_link_endpoint[0].dns_domain

  vpc {
    vpc_id = module.awsvpcs.vpc_id
  }

  tags = {
    Owner = var.owner
  }
}

# Gateway mode: wildcard DNS record
resource "aws_route53_record" "gateway_privatelink" {
  count   = var.privatelink_mode == "gateway" ? 1 : 0
  zone_id = aws_route53_zone.gateway_privatelink[0].zone_id
  name    = "*"
  type    = "CNAME"
  ttl     = 60
  records = [aws_vpc_endpoint.gateway_privatelink[0].dns_entry[0]["dns_name"]]
}

# NLB target group attachments (created after VPC endpoint exists)
resource "aws_lb_target_group_attachment" "cc-kafka-to-pl" {
  target_group_arn = module.awsvpcs.kafka_target_group_arn
  target_id        = var.privatelink_mode == "platt" ? tolist(module.privatelink[0].vpc_endpoint.subnet_configuration)[0].ipv4 : tolist(aws_vpc_endpoint.gateway_privatelink[0].subnet_configuration)[0].ipv4
  port             = 9092
}

resource "aws_lb_target_group_attachment" "cc-rest-to-pl" {
  target_group_arn = module.awsvpcs.rest_target_group_arn
  target_id        = var.privatelink_mode == "platt" ? tolist(module.privatelink[0].vpc_endpoint.subnet_configuration)[0].ipv4 : tolist(aws_vpc_endpoint.gateway_privatelink[0].subnet_configuration)[0].ipv4
  port             = 443
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

module "cc_dataplane" {
  source                   = "./cc-dataplane"

  # Don't attempt any DataPlane API calls if we can't access it yet
  # Enable this after initial apply when DNS is configured: TF_VAR_enable_dataplane=true
  count                    = var.enable_dataplane ? 1 : 0

  app-manager-sa           = module.cc_controlplane.app-manager
  app-consumer-sa          = module.cc_controlplane.app-consumer
  app-producer-sa          = module.cc_controlplane.app-producer
  kafka-cluster            = module.cc_controlplane.enterprise_cluster
  plac                     = var.privatelink_mode == "platt" ? confluent_private_link_attachment_connection.plac[0] : null
  access_point             = var.privatelink_mode == "gateway" ? confluent_access_point.gateway[0] : null
  app-manager-is-cluster-admin = module.cc_controlplane.am-cluster-admin
  cc-environment           = module.cc_controlplane.cc_environment
  //owner                    = var.owner
  env_prefix               = var.env_prefix
}

output "connection_info" {
  value = [
    for v in module.cc_dataplane: "${v.resource-ids}"
  ]
  /*
  value = <<-EOT
  ${module.cc_dataplane[*].resource-ids}
  EOT
  */

  sensitive = true
}


