terraform {
  backend "remote" {
    organization = "rsr-projects"
    workspaces {
      name = "testing-jenkins-gpt"
    }
    
  }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.89.0"
    }
  }
}

provider "aws" {
  region = "eu-west-1"
}

resource "aws_instance" "app_server" {
  ami           = "ami-03fd334507439f4d1" # Ubuntu 24.04
  instance_type = "t2.micro"
  key_name = "rsrkey"
  security_groups = [aws_security_group.rsr-sg.name]
  user_data = <<-EOF
              #!/bin/bash
              sudo apt-get update -y
              sudo apt-get install docker.io -y
              systemctl start docker
              systemctl enable docker
              sudo docker pull rsrprojects/flask-news-app:test
              sudo docker run -d -p 5000:5000 rsrprojects/flask-news-app:test
              EOF
  tags = {
    Name = "news-web-app"
  }
}

resource "aws_security_group" "rsr-sg" {
  name        = "rsr-sg"
  description = "Allow inbound traffic"
  
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  ingress {
    from_port   = 5000
    to_port     = 5000
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

output "ec2_public_ip" {
  value = aws_instance.app_server.public_ip
}