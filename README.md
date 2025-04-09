# atg_cc_enterprise_via_nlb


Uses a NLB on AWS to expose a Confluent Cloud Enterprise cluster with a public endpoint

NB! this is just a proof-of-concept, so it only uses a single AZ with a single Private Link endpoint. This is a single point of failure. For production use it would need to be extended to use at least 2 of the possible 3 endpoints to connect to the Confluent Cloud Network.

### Notes

Before running Terraform, create a keypair for the jumphost
```
cd aws/jump-host
ssh-keygen -t rsa -b 4096 -m pem -f jumphost_kp && openssl rsa -in jumphost_kp -outform pem && chmod 400 jumphost_kp
cd ../..
```

This set-up uses the `CONFLUENT_CLOUD_API_KEY` and `CONFLUENT_CLOUD_API_SECRET` environment variables to authorise itself to create clusters, topics, API keys for cluster access etc. This must be a [cloud api key](https://support.confluent.io/hc/en-us/articles/11113978002836-What-are-the-differences-of-Cloud-API-Keys-Cluster-Resource-specific-API-Keys)
```
export CONFLUENT_CLOUD_API_KEY="<cloud_api_key>"
export CONFLUENT_CLOUD_API_SECRET="<cloud_api_secret>"
export TF_VAR_owner=
export TF_VAR_region=
```

Run this by carrying out
```
terraform init
terraform plan
terraform apply
```

The last module `cc_dataplane` will be skipped in the first run as there is no DNS to resolve the Fully Qualified Domain Name of the bootstrao server to an accessible IP address.

At this stage the public IP address should have been set up, so you can access it via
```
terraform output endpoint_info
```

If you can add an entry in your local /etc/hosts file (or DNS) so that the FQDN of the cluster endpoint public IP address then when you re-run `terraform apply` the API key generation should succeed and the topic will be created.

In order to be able to access the Kafka APIs your DNS should resolve the wildcard `*.<region>.aws.private.confluent.cloud` to the public IP address of the NLB. Look at the `connection_info` output from Terraform to retrieve the newly create cluster API keys and some example commands for producing to and consuming from the topic using the [Confluent CLI tool](https://docs.confluent.io/confluent-cli/current/install.html).

```
terraform output connection_info
```


----

This repository is part of the Confluent organization on GitHub.
It is public and open to contributions from the community.

Please see the LICENSE file for contribution terms.
Please see the CHANGELOG.md for details of recent updates.


