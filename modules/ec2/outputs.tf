output "instance_id" {
  value = aws_instance.web.id
}

output "public_ip" {
  value = aws_instance.web.public_ip
}

output "security_group" {
  value = aws_security_group.ec2_sg.id
}


output "security_group_id" {
  description = "The ID of the security group created for EC2"
  value       = aws_security_group.ec2_sg.id
}