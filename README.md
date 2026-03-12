# atg_cc_enterprise_via_nlb
![image](images/confluent-logo-300-2.png)

Uses a NLB on AWS to expose a Confluent Cloud Enterprise cluster with a public endpoint

### Prerequisites

1. AWS client configured so that the *hashicorp/aws* provider can create resources in your AWS account.
2. A Confluent Cloud API key in order to create resources in your CC Organization.
3. Terraform with Confluent provider version >= 2.50.0 (for Gateway + Access Point support)
4. The `netcat/nc` tool installed and on your path in order to test network connectivity to CC
5. ssh-keygen installed in order to create a keypair to access the jump-host on AWS
6. Confluent CLI installed (optional)

### What does this Terraform setup do?

1. Creates an Enterprise cluster in Confluent Cloud. This cluster can only be accessed via a private network connection.
2. Creates a VPC in your account containing two subnets one *public*, the other *private*
4. Creates a Private Link endpoint for the Confluent Cloud Network and places in the *private* subnet
5. Sets up a private DNS zone in order to resolve the CC FQDNs to the PL address
5. Instantiates a VM in the *private* subnet and gives it a public IP address
6. Creates a Network Load Balancer,assigns it a public IP address and attaches it to the *public* subnet
7. Sets the PL endpoint as the target for the NLB

![Architecture Diagram](images/architecture.png)

Thus we end up with an NLB on the public internet which forwards traffic (on ports 443 (REST) and 9092 (Kafka)) to the PL endpoint which gives access to the Enterprise Cluster. In order for this to be useful it requires some DNS changes.

The purpose of the VM is to make it possible to test Kafka connectivity to the cluster via the private link. It's accessible via ssh. 

Any clients accessing the public endpoint need to resolve both the bootstrap FQDN and all the broker FQDNs to the public IP address of the NLB.

**For PLATT mode:** FQDNs have the form `<lkc_id>.<region>.<csp>.private.confluent.cloud` and `<lkc_id>_<broker_hex>.<region>.<csp>.private.confluent.cloud`

**For Gateway mode:** The DNS domain is automatically provided by the Confluent Access Point and has a format specific to your cluster and gateway configuration.

This requires a wildcard mapping in the DNS. The exact domain pattern is output by Terraform after the access point is created. For Gateway mode, use the DNS domain from the access point output to configure your DNS:
```
address=/*.{dns_domain_from_access_point}/34.242.88.53
```

For PLATT mode:
```
address=/eu-west-1.aws.private.confluent.cloud/34.242.88.53
```

NB! this is just a proof-of-concept, so it only uses a single AZ with a single Private Link endpoint. This is a single point of failure. For production use it would need to be extended to use at least 2 of the possible 3 PL endpoints to connect to the Confluent Cloud Network that the cluster is in. The ingress security groups on the NLB and jumphost should also be tightened up as much as possible.

### Notes

Before running Terraform, create a keypair for the jumphost
```shell
cd aws/jump-host
ssh-keygen -t rsa -b 4096 -m pem -f jumphost_kp && openssl rsa -in jumphost_kp -outform pem && chmod 400 jumphost_kp
cd ../..
```

This set-up uses the `CONFLUENT_CLOUD_API_KEY` and `CONFLUENT_CLOUD_API_SECRET` environment variables to authorise itself to create clusters, topics, API keys for cluster access etc. This must be a [cloud api key](https://support.confluent.io/hc/en-us/articles/11113978002836-What-are-the-differences-of-Cloud-API-Keys-Cluster-Resource-specific-API-Keys)

Before running Terraform, set the following variables
```shell
export CONFLUENT_CLOUD_API_KEY="<cloud_api_key>"
export CONFLUENT_CLOUD_API_SECRET="<cloud_api_secret>"
export TF_VAR_owner=<email address to tag AWS resources>
export TF_VAR_region=<AWS region to use, defaults to eu-west-1/Ireland>
export TF_VAR_privatelink_mode=<platt or gateway, defaults to gateway>
# export TF_VAR_enable_dataplane=true  # Set to true after initial apply when DNS is configured
```

### PrivateLink Architecture Modes

This setup supports two PrivateLink architectures:

**1. Gateway + Access Point Mode** (default)
- Uses `confluent_gateway` (ingress) and `confluent_access_point`
- DNS domain format: configured via access point
- Set `TF_VAR_privatelink_mode=gateway`

**2. Private Link Attachment (PLATT) Mode**
- Uses `confluent_private_link_attachment` and `confluent_private_link_attachment_connection`
- DNS domain format: `<network_id>.<region>.<cloud>.private.confluent.cloud`
- Set `TF_VAR_privatelink_mode=platt`

The setup automatically configures DNS routing based on the selected mode.

And then use Terraform to create the various AWS resources and create the Confluent Cloud Environment and Cluster.
```shell
terraform init
terraform plan
terraform apply
```

**Note:** The `cc_dataplane` module (which creates API keys and topics) is disabled by default (`enable_dataplane = false`). This is because it requires DNS connectivity to the cluster, which won't be available until after the initial infrastructure is created and DNS is configured.

At this stage the public IP address should have been set up, so you can access it via
```shell
terraform output endpoint_info
```

If you can add an entry in your local `/etc/hosts` file (or DNS) so that the FQDN of the cluster endpoint points to the public IP address, then you can enable the dataplane module:
```shell
export TF_VAR_enable_dataplane=true
terraform apply
```
This will create the API keys and topics now that DNS connectivity is available.

In order to be able to access the Kafka APIs (i.e. using a Kafka client) your DNS should resolve the appropriate wildcard to the public IP address of the NLB:
- **PLATT mode:** `*.<region>.aws.private.confluent.cloud`
- **Gateway mode:** Use the DNS domain provided by the Access Point (check terraform outputs for the exact domain)

Look at the `connection_info` output from Terraform to retrieve the newly created cluster API keys and some example commands for producing to and consuming from the topic using the [Confluent CLI tool](https://docs.confluent.io/confluent-cli/current/install.html).

```shell
terraform output connection_info
```


----

This repository is part of the Confluent organization on GitHub.
It is public and open to contributions from the community.

Please see the LICENSE file for contribution terms.
Please see the CHANGELOG.md for details of recent updates.


