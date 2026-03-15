resource "aws_security_group" "ec2_sg" {

  name        = "${var.project_name}-${var.environment}-ec2-sg"
  description = "Allow SSH and HTTP"
  vpc_id      = var.vpc_id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {

    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]

  }

}

resource "aws_instance" "web" {
  ami           = var.ami_id
  instance_type = var.instance_type
  subnet_id     = var.subnet_id 
  vpc_security_group_ids = [aws_security_group.ec2_sg.description]
  user_data = var.user_data != "" ? var.user_data : <<-EOF
    #!/bin/bash
    yum update -y
    yum install -y amazon-cloudwatch-agent aws-cli

    # Start SSM agent
    systemctl enable amazon-ssm-agent
    systemctl start amazon-ssm-agent

    # Start CloudWatch agent
    /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
      -a fetch-config -m ec2 -s
  EOF
  tags = {
    Name = "${var.project_name}-${var.environment}-web"
  }
}