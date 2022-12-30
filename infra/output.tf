output "vm_public_ip" {
  value = aws_spot_instance_request.vm.public_ip
}