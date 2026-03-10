# PrivateLink Architecture Support

This repository now supports both PrivateLink architectures for Confluent Cloud Enterprise clusters.

## Modes

### 1. PLATT Mode (Default)
Uses the traditional Private Link Attachment architecture:
- Creates `confluent_private_link_attachment`
- Creates `confluent_private_link_attachment_connection`
- DNS domain format: `<network_id>.<region>.<cloud>.private.confluent.cloud`

**Usage:**
```bash
export TF_VAR_privatelink_mode=platt
# or simply omit the variable as 'platt' is the default
terraform apply
```

### 2. Gateway + Access Point Mode
Uses the newer Gateway and Access Point architecture:
- Creates `confluent_network` with PRIVATELINK connection type
- Creates `confluent_gateway` (AWS Egress Private Link Gateway)
- Creates `confluent_private_link_access_point`
- DNS domain format: `<gateway_id>.<region>.<cloud>.egress.glb.confluent.cloud`

**Usage:**
```bash
export TF_VAR_privatelink_mode=gateway
terraform apply
```

## What Changed

### New Variables
- `privatelink_mode` - Choose between "platt" or "gateway" (default: "platt")

### Modified Files
- `variables.tf` - Added `privatelink_mode` variable with validation
- `main.tf` - Passes mode to cc-controlplane module and access_point to cc-dataplane
- `cc-controlplane/main.tf` - Conditional resources based on mode
- `cc-controlplane/variables.tf` - Added `privatelink_mode` variable
- `cc-controlplane/outputs.tf` - Conditional outputs for both modes
- `cc-dataplane/main.tf` - Updated depends_on to handle both connection types
- `cc-dataplane/variables.tf` - Added `access_point` variable
- `README.md` - Documentation for both modes

## DNS Resolution

The setup automatically configures Route53 private hosted zones based on the selected mode:
- **PLATT mode**: Creates DNS entries for `*.<network_id>.<region>.<cloud>.private.confluent.cloud`
- **Gateway mode**: Creates DNS entries for `*.<gateway_id>.<region>.<cloud>.egress.glb.confluent.cloud`

Both modes resolve to the same VPC endpoint that routes through the NLB to the public internet.

## Migration

To switch between modes:
1. Destroy existing infrastructure: `terraform destroy`
2. Change the `TF_VAR_privatelink_mode` environment variable
3. Re-apply: `terraform apply`

**Note:** You cannot change modes without destroying and recreating resources, as they use different Confluent Cloud networking architectures.
