#--- rootmain.tf ---#

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "us-east-1"
}
module "Networking" {
  vpc_id = "default"
  source = ./TF-2-tier/Networking
}
# Security group for public subnets
resource "aws_security_group" "public_security" {
  vpc_id      = aws_vpc.main_vpc.id
  name        = "public_security"
  description = "Allow traffic"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
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

# Load balancer
resource "aws_lb" "my_alb" {
  name               = "my-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.public_security.id]
  subnets            = [aws_subnet.public-1.id, aws_subnet.public-2.id]
}

# Target group
resource "aws_lb_target_group" "my_target" {
  name     = "my-target"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main_vpc.id

  depends_on = [
    aws_vpc.main_vpc
  ]
}

resource "aws_lb_target_group_attachment" "attachment-1" {
  target_group_arn = aws_lb_target_group.my_target.arn
  target_id        = aws_instance.ec2-1.id
  port             = 80

  depends_on = [
    aws_instance.ec2-1
  ]
}

resource "aws_lb_target_group_attachment" "attachment-2" {
  target_group_arn = aws_lb_target_group.my_target.arn
  target_id        = aws_instance.ec2-2.id
  port             = 80

  depends_on = [
    aws_instance.ec2-2
  ]
}

# Listener
resource "aws_lb_listener" "listener_balance" {
  load_balancer_arn = aws_lb.my_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.my_target.arn
  }
}

# EC2's
resource "aws_instance" "ec2-1" {
  ami                         = "ami-026b57f3c383c2eec"
  instance_type               = "t2.micro"
  key_name                    = "Djw9799djW"
  availability_zone           = "us-east-1a"
  vpc_security_group_ids      = [aws_security_group.public_security.id]
  subnet_id                   = aws_subnet.public-1.id
  associate_public_ip_address = true
  user_data                   = <<-EOF
        #!/bin/bash
        yum update -y
        yum install httpd -y
        systemctl start httpd
        systemctl enable httpd
        echo "<html><body><h1>What's up everyone</h1></body></html>" > /var/www/html/index.html
        EOF

  tags = {
    Name = "first_instance"
  }
}

resource "aws_instance" "ec2-2" {
  ami                         = "ami-026b57f3c383c2eec"
  instance_type               = "t2.micro"
  key_name                    = "Djw9799djW"
  availability_zone           = "us-east-1b"
  vpc_security_group_ids      = [aws_security_group.public_security.id]
  subnet_id                   = aws_subnet.public-2.id
  associate_public_ip_address = true
  user_data                   = <<-EOF
        #!/bin/bash
        yum update -y
        yum install httpd -y
        systemctl start httpd
        systemctl enable httpd
        echo "<html><body><h1>What's up everyone</h1></body></html>" > /var/www/html/index.html
        EOF

  tags = {
    Name = "second_instance"
  }
}

# RDS
resource "aws_db_instance" "database" {
  allocated_storage      = 5
  engine                 = "mysql"
  engine_version         = "5.7"
  instance_class         = "db.t3.micro"
  identifier             = "db-instance"
  db_name                = "database_1"
  username               = "admin"
  password               = "password"
  db_subnet_group_name   = aws_db_subnet_group.group_subnet.id
  vpc_security_group_ids = [aws_security_group.public_security.id]
  publicly_accessible    = false
  skip_final_snapshot    = true
}

resource "aws_db_subnet_group" "group_subnet" {
  name       = "group_subnet"
  subnet_ids = [aws_subnet.public-1.id, aws_subnet.public-2.id]
}

output "public_ip-1" {
  value = aws_instance.ec2-1.public_ip
}
output "public_ip-2" {
  value = aws_instance.ec2-2.public_ip
}