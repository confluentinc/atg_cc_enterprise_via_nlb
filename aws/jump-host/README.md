Create a keypair for the jumphost (before running Terraform)

ssh-keygen -t rsa -b 4096 -m pem -f jumphost_kp && openssl rsa -in jumphost_kp -outform pem && chmod 400 jumphost_kp

Once the jumphost is created you can access it via ssh

Some tips on checking that the path to the Enterprise cluster is up and accessible
https://docs.confluent.io/cloud/current/networking/testing.html


