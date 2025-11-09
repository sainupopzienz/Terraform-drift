data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

resource "aws_key_pair" "main" {
  key_name   = var.key_name
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDRYhukv1rtE9W9epFiX5QTRxxx8XtviMi/X9NcfAwj5BhUY4bDJOvmJeN8SS16acMXXjwSBowv7Eu40vmAcApImZ25l4vtSaXAIltomKovA02Ca97Z35y7rOm29oa5brR4sblcVxp2AUR3vz6vI3ZQpUhCYjxdlt/eCor53uxG2xhM0RNyOt+i59AUXQDe/SDKLdJEKvtysrok4yVbPRPIgBWp8tKUKbGQpagAwoe57XrJqsB+h7cecdoL2KyX6EmvcSv6q6SeBClgVpHgffgk/MJXFp/VFCoux4K8t8AE+rwGUy7sm3GQZ2EhA5CIqhTDNX/wbUfn3m2qTIeinT4r"
}

resource "aws_security_group" "ec2" {
  name_prefix = "terraform-drift-ec2-"
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

  tags = merge(var.tags, {
    Name = "terraform-drift-ec2-sg"
  })
}

resource "aws_instance" "main" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = var.instance_type
  key_name              = aws_key_pair.main.key_name
  vpc_security_group_ids = [aws_security_group.ec2.id]
  subnet_id             = var.public_subnet_ids[0]

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y httpd
              systemctl start httpd
              systemctl enable httpd
              echo "<h1>Terraform Drift Test Server</h1>" > /var/www/html/index.html
              EOF

  tags = merge(var.tags, {
    Name = "terraform-drift-ec2"
  })
}
