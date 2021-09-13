terraform {
  required_providers {
    scaleway = {
      source = "scaleway/scaleway"
    }
  }
  required_version = ">= 0.13"
}

provider "scaleway" {
  zone            = "nl-ams-1"
  region          = "nl-ams"
}

locals {
  instance_type = "DEV1-M"
  tags = [ "mqmft", "lab" ]
  count = 1
}

resource "scaleway_instance_ip" "public_ip" {
count = local.count
}

resource "scaleway_instance_security_group" "mqmft" {
  inbound_default_policy  = "accept"
  outbound_default_policy = "accept"
  name = "mqmft-${terraform.workspace}"
}

resource "scaleway_instance_server" "mqmft" {
  count = local.count
  name  = "mqmft-${count.index}"
  type  = local.instance_type
  image = "centos_8"
  tags = local.tags
  enable_ipv6 = false
  ip_id = scaleway_instance_ip.public_ip[count.index].id
  security_group_id = scaleway_instance_security_group.mqmft.id
#  provisioner "local-exec" {
#    command = "ansible-playbook -i '${self.public_ip},' playbook.yml -e \"provider=scaleway\""
#  }

  connection {
    type = "ssh"
    user = "root"
    private_key = file("~/.ssh/id_rsa")
    host = self.public_ip
  }

  provisioner "remote-exec" {
    inline = [
      "dnf -y install git",
      "git clone https://github.com/goffinet/mftlab",
      "cd mftlab",
      "bash startup.sh"
    ]
  }
}
