output "private_ip" {
  value = aws_instance.jumphost.private_ip
}
output "public_ip" {
  value = aws_eip.jump_eip.public_ip
}