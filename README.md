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

This set-up uses the following variables
```
export TF_VAR_owner=
export TF_VAR_confluent_cloud_api_key=
export TF_VAR_confluent_cloud_api_secret=
export TF_VAR_region=
```

Run this by carrying out
```
terraform init
terraform plan
terraform apply
```

The last module `cc_dataplane` will probably fail with an error as Terraform will attempt to validate API key creation by listing topics, which will fail without access to the Kafka REST API. The errors look like:

        ```
        Error: error waiting for Kafka API Key "[REDACTED]" to sync: error listing Kafka Topics using Kafka API Key "[REDACTED]": Get "[https://[REDACTED]/kafka/v3/clusters/[REDACTED]/topics](https://[REDACTED]/kafka/v3/clusters/[REDACTED]/topics)": GET [https://[REDACTED]/kafka/v3/clusters/[REDACTED]/topics](https://[REDACTED]/kafka/v3/clusters/[REDACTED]/topics) giving up after 5 attempt(s): Get "[https://[REDACTED]/kafka/v3/clusters/[REDACTED]/topics](https://[REDACTED]/kafka/v3/clusters/[REDACTED/topics)": dial tcp [REDACTED]:443: i/o timeout
        ```

At this stage the public IP address should have been set up, so you can access it via
```
terraform output connection_info
```

If you can add an entry in your local /etc/hosts file (or DNS) so that the FQDN of the cluster endpoint public IP address then when you re-run `terraform apply` the API key generation should succeed.

----

This repository is part of the Confluent organization on GitHub.
It is public and open to contributions from the community.

Please see the LICENSE file for contribution terms.
Please see the CHANGELOG.md for details of recent updates.


