terraform {
  required_providers {
    aws  = { source = "hashicorp/aws" }
    http = { source = "hashicorp/http" }
  }
}

provider "aws" {
  region = "us-east-1"
}

variable "instance_count" {
  type    = number
  default = 1
}

variable "instance_type" {
  type    = string
  default = "t2.micro"
}

variable "ssh_cidr" {
  type    = string
  default = ""
}

# Path to SSH private key
variable "private_key_path" {
  type    = string
  default = "/root/.ssh/master-key.pem"
}

data "http" "my_ip" {
  url = "https://checkip.amazonaws.com/"
}

locals {
  public_ip = trimspace(data.http.my_ip.response_body)
  ssh_cidr  = var.ssh_cidr != "" ? var.ssh_cidr : "${local.public_ip}/32"
}

data "aws_ami" "ubuntu_focal" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }
}

resource "aws_security_group" "ssh" {
  name_prefix = "tf-sg-ssh-grafana-"
  description = "Allow SSH, Grafana, Prometheus inbound"

  # SSH
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Grafana
  ingress {
    description = "Grafana"
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Prometheus
  ingress {
    description = "Prometheus"
    from_port   = 9090
    to_port     = 9090
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Outbound (all)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "example" {
  count         = var.instance_count
  ami           = data.aws_ami.ubuntu_focal.id
  instance_type = var.instance_type
  key_name      = "master-key"

  vpc_security_group_ids = [aws_security_group.ssh.id]

  tags = {
    Name = "tf-example-${count.index + 1}"
  }
}

resource "null_resource" "ansible_provision" {
  triggers = {
    instance_ips = join(",", aws_instance.example[*].public_ip)
  }

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]

    command = <<EOT
./scripts/generate_ansible_inventory.sh "${var.private_key_path}" "./ansible/inventory.ini" && \
ansible-playbook -i ./ansible/inventory.ini ./ansible/playbook.yml
EOT
  }

  depends_on = [
    aws_instance.example,
    aws_security_group.ssh
  ]
}
