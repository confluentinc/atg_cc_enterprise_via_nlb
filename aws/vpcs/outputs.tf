output "vpc_id" {
  value = aws_vpc.vpc.id
}

output "private_subnet_id" {
  value = aws_subnet.private_subnet[0].id
}
output "public_subnet_id" {
  value = aws_subnet.private_subnet[0].id
  //value = aws_subnet.public_subnet[0].id
}
output "loadbalancer_sg" {
  value = aws_security_group.cc_access
}

output "loadbalancer_ip" {
  value = aws_eip.nlb_eip
}

