Creates the API keys and topics in the Enterprise cluster. 

We separate this from the creation of the cluster as it can only be done once we have connection to the cluster via PrivateLink

It also needs to have the DNS of the machine where Terraform runs updated so that the FQDN of the bootstrap URL of the cluster points to the public IP address assigned to the NLB. See the main README for more details

This is based on the examples in the Confluent Terraform provider, in particular examples/configurations/enterprise-privatelinkattachment-aws-kafka-acls