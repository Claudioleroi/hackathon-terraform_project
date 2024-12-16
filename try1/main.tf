terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> "
    }
  }
}



provider "aws" {
    region="us-east-1"
    access_key = ""
    secret_key = ""
}


resource "tls_private_key" "rsa_4096" {
  algorithm = "RSA"
  rsa_bits  = 4096
}


variable "key_name" {

}
resource "aws_key_pair" "key_pair" {
  key_name   = var.key_name
  public_key = tls_private_key.rsa_4096.public_key_openssh
}

resource "local_file" "private_key" {
content =tls_private_key.rsa_4096.private_key_pem
filename = var.key_name

}
resource "aws_security_group" "sg_ec2" {
  name        = "sg_ec2"
  description = "Security group for EC2"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
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

resource "aws_instance" "hackathon_instance" {
  ami           = "ami-00c71bd4d220aa22a"
  instance_type = "t2.micro"
  key_name= aws_key_pair.key_pair.key_name

  tags = {
    Name = "terrraform_instance"
  }
}
  root_block_device {
    volume_size = 30
    volume_type = "gp2"
  }
connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = tls_private_key.rsa_4096.private_key_pem
    host        = self.public_ip
  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt update -y",
      "sudo apt upgrade ",
      "sudo apt install apache2 -y",
      "sudo systemctl start apache2",
      "sudo systemctl enable apache2",
      "sudo apt install mariadb-server mariadb-client -y",
      "sudo systemctl start mariadb",
      "sudo systemctl enable mariadb",
      "sudo mysql-secure-installation",
       "sudo systemctl restart mariadb",
       "sudo apt install php-mysql php-gd php-cli php-common -y",
 
    ]
  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt install wget -y",
      "sudo wget  https://wordpress.org/latest.zip",
      "sudo unzip latest.zip",
      "sudo cp -r wordpress/* /var/www/html/",
      "cd /var/www/html/",
      "sudo chown -R www-data:www-data /var/www/html/",
      "sudo rm -rf index.html",
      "cd",
    ]
  }

  provisioner "remote-exec" {
    inline = [
      "sudo mysql -u root -p \"CREATE DATABASE wordpress;\"",
      "sudo mysql -u root -p \"CREATE USER 'wpadmin' IDENTIFIED BY 'wpadminpass';\"",
      "sudo mysql -u root -p \"GRANT ALL PRIVILEGES ON wordpress.* TO 'wpadmin';\"",
      "sudo mysql -u root -p \"FLUSH PRIVILEGES;\"",
    ]
  }
}

