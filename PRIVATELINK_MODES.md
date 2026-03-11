# PrivateLink Architecture Support

This repository now supports both PrivateLink architectures for Confluent Cloud Enterprise clusters.

## Modes

### 1. PLATT Mode
Uses the traditional Private Link Attachment architecture:
- Creates `confluent_private_link_attachment`
- Creates `confluent_private_link_attachment_connection`
- DNS domain format: `<network_id>.<region>.<cloud>.private.confluent.cloud`

**Usage:**
```bash
export TF_VAR_privatelink_mode=platt
terraform apply
```

### 2. Gateway + Access Point Mode (Default)
Uses the newer Gateway and Access Point architecture:
- Creates `confluent_gateway` with AWS Ingress Private Link Gateway
- Creates `confluent_access_point` with AWS Ingress Private Link Endpoint
- Gateway outputs VPC Endpoint Service Name for creating AWS VPC Endpoint
- Access Point registers the VPC Endpoint ID and outputs DNS domain

**Usage:**
```bash
export TF_VAR_privatelink_mode=gateway
# or simply omit the variable as 'gateway' is the default
terraform apply
```

## What Changed

### Provider Requirements
- **Confluent provider upgraded to >= 2.50.0** to support `aws_ingress_private_link_gateway` and `aws_ingress_private_link_endpoint` resources

### New Variables
- `privatelink_mode` - Choose between "platt" or "gateway" (default: "gateway")

### Key Changes
- **Gateway mode uses Ingress resources**: `confluent_gateway` with `aws_ingress_private_link_gateway` block and `confluent_access_point` with `aws_ingress_private_link_endpoint` block
- **Resource separation**: `confluent_access_point` and `confluent_private_link_attachment_connection` resources moved to `main.tf` to avoid circular dependencies
- **Conditional VPC endpoint creation**: Gateway mode creates VPC endpoint and Route53 zone directly in main.tf, while PLATT mode uses the privatelink-endpoint module
- **NLB target attachments**: Made conditional and moved outside vpc module to break dependency cycles

### Modified Files
- `main.tf` - Added gateway mode VPC endpoint, access point, Route53 resources, and NLB target attachments
- `variables.tf` - Added `privatelink_mode` variable with validation
- `cc-controlplane/main.tf` - Conditional gateway resources (connection moved to main.tf)
- `cc-controlplane/variables.tf` - Added `privatelink_mode` variable
- `cc-controlplane/outputs.tf` - Conditional outputs for both modes
- `cc-dataplane/variables.tf` - Added `access_point` variable
- `aws/vpcs/main.tf` - Made NLB target attachments conditional
- `aws/vpcs/variables.tf` - Made `pl_endpoints` optional with default empty list
- `aws/vpcs/outputs.tf` - Added target group ARN outputs
- `README.md` - Documentation for both modes

## DNS Resolution

The setup automatically configures Route53 private hosted zones based on the selected mode:
- **PLATT mode**: Creates DNS entries for `*.<network_id>.<region>.<cloud>.private.confluent.cloud` (from Private Link Attachment)
- **Gateway mode**: Creates DNS entries using the domain automatically provided by the Access Point (check `confluent_access_point.gateway[0].aws_ingress_private_link_endpoint[0].dns_domain` output)

Both modes create their own VPC endpoints that route through the NLB to the public internet.

## Resource Creation Flow

### PLATT Mode:
1. `confluent_private_link_attachment` → outputs VPC Endpoint Service Name
2. AWS VPC Endpoint created using service name
3. `confluent_private_link_attachment_connection` → registers VPC endpoint with Confluent
4. Route53 zone created using dns_domain from attachment

### Gateway Mode:
1. `confluent_gateway` with ingress config → outputs VPC Endpoint Service Name
2. AWS VPC Endpoint created using service name
3. `confluent_access_point` with ingress endpoint → registers VPC endpoint and outputs dns_domain
4. Route53 zone created using dns_domain from access point

## Switching Modes

To switch between modes:
1. Change the `TF_VAR_privatelink_mode` environment variable
2. Run `terraform plan` to review the changes
3. Run `terraform apply` to apply the changes
