packer {
  required_plugins {
    amazon = {
      version = ">= 1.2.8"
      source  = "github.com/hashicorp/amazon"
    }
    ansible = {
      version = ">= 1.1.1"
      source  = "github.com/hashicorp/ansible"
    }
  }
}

variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "source_ami_name" {
  type    = string
  default = "ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-arm64-server-*"
}

source "amazon-ebs" "eks_worker" {
  region        = var.aws_region
  instance_type = "t4g.medium"
  ssh_username  = "ubuntu"
  ami_name      = "swimlane-eks-worker-{{timestamp}}"

  source_ami_filter {
    filters = {
      name                = var.source_ami_name
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }
    owners      = ["099720109477"]
    most_recent = true
  }
}

build {
  sources = ["source.amazon-ebs.eks_worker"]

  provisioner "ansible" {
    playbook_file = "../ansible/worker-node.yml"
  }
}
