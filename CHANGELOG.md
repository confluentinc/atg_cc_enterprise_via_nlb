# Change Log

## v0.1.0 - 2026-03-11

### Features

- Added support for Gateway + Access Point PrivateLink architecture
- Made Gateway mode the default (can switch to PLATT with `privatelink_mode = "platt"`)
- Upgraded Confluent provider requirement to >= 2.50.0 for ingress gateway support
- Refactored resource dependencies to eliminate circular dependencies
- Made NLB target group attachments conditional to support both architectures

### Changes

- Moved `confluent_access_point` and `confluent_private_link_attachment_connection` resources to main.tf
- Gateway mode now uses `aws_ingress_private_link_gateway` and `aws_ingress_private_link_endpoint`
- VPC endpoint and Route53 zone creation now mode-specific in main.tf
- Updated documentation for both PrivateLink modes

### Fixes

- Fixed circular dependency issues between VPC endpoint, Confluent resources, and NLB targets
- Corrected resource types and attribute references for gateway mode

## v0.0.0 - Initial Development

### Features and Fixes

- Initial release with PLATT mode support
