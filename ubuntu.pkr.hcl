packer {
  required_plugins {
    amazon = {
      source  = "github.com/hashicorp/amazon"
      version = "~> 1"
    }
  }
}

source "amazon-ebs" "ubuntu" {
  region        = "us-east-1"
  instance_type = "t3.medium"

  ami_name = "company-ubuntu-golden-{{timestamp}}"

  source_ami_filter {
    filters = {
      name                = "ubuntu/images/hvm-ssd-gp3/ubuntu-resolute-26.04-amd64-server-*"
      architecture        = "x86_64"
      virtualization-type = "hvm"
      root-device-type    = "ebs"
    }

    owners      = ["099720109477"]
    most_recent = true
  }

  ssh_username = "ubuntu"
}

build {
  sources = ["source.amazon-ebs.ubuntu"]

  provisioner "shell" {
    inline = [
      "sudo apt-get update",
      "sudo apt-get install -y docker.io git curl unzip jq",
      "sudo systemctl enable docker"
    ]
  }
}


---------------------------------------------AZURE--------------------------------------------------


packer {
  required_plugins {
    azure = {
      source  = "github.com/hashicorp/azure"
      version = "~> 2"
    }
  }
}

source "azure-arm" "ubuntu" {
  use_azure_cli_auth = true

  subscription_id = "YOUR_SUBSCRIPTION_ID"

  managed_image_resource_group_name = "golden-images-rg"
  managed_image_name                = "company-ubuntu-golden"

  location = "Central India"
  vm_size  = "Standard_B2s"

  os_type         = "Linux"
  image_publisher = "Canonical"
  image_offer     = "ubuntu-24_04-lts"
  image_sku       = "server"

  azure_tags = {
    Environment = "Production"
    CreatedBy   = "Packer"
    ImageType   = "Golden"
  }
}

build {
  sources = ["source.azure-arm.ubuntu"]

  provisioner "shell" {
    inline = [
      "sudo apt-get update",
      "sudo apt-get install -y docker.io git curl unzip jq",
      "sudo systemctl enable docker",
      "sudo waagent -deprovision+user -force"
    ]
  }
}



