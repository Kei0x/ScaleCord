# variable "sw_organization" {
#     type = "string"
#     # description = "The Scaleway organization ID."
# }

# variable "sw_token" {
#     type = "string"
#     # description = "The Scaleway secret token."
# }

variable "scw_ssh_public_key" {
    type = "string"
    description = "SSH public key (file)."
}

variable "scw_ssh_private_key" {
    type = "string"
    description = "SSH private key (file)."
}

variable "discord_deb" {
    type = "string"
    default = "https://dl.discordapp.net/apps/linux/0.0.9/discord-0.0.10.deb"
    description = "Discord download URL."
}

provider "scaleway" {
    # organization = "${var.sw_organization}"
    # token = "${var.sw_token}"
    region = "par1"
}

data "scaleway_image" "debian" {
    architecture = "x86_64"
    name = "Debian Stretch"
}

resource "scaleway_ssh_key" "discord" {
    key = "${file("${var.scw_ssh_public_key}")}"
}

resource "scaleway_server" "discord" {
    name = "discord"
    image = "${data.scaleway_image.debian.id}"
    type = "DEV1-L"
    dynamic_ip_required = true

    provisioner "remote-exec" {
        connection {
            type = "ssh"
            user = "root"
            private_key = "${file("${var.scw_ssh_private_key}")}"
        }

        inline = [
            "export DEBIAN_FRONTEND=noninteractive",
            "apt-get -yqq update && apt-get -yqq upgrade",
            "apt-get -yqq install curl libasound2 libatomic1 libgconf-2-4 libnotify4 libxss1 libxtst6 libappindicator1 libc++1",
            "curl -JLo discordapp.deb ${var.discord_deb}",
            "dpkg -i discordapp.deb",
            "sed -i.bak -e '/^#X11Forwarding/c\\\nX11Forwarding yes' /etc/ssh/sshd_config",
            "sed -i.bak -e '/^#X11UseLocalhost/c\\\nX11UseLocalhost no' /etc/ssh/sshd_config",
            "systemctl -q reload sshd",
            "mkdir bin",
            "echo '#!/bin/sh\ndiscord\nsleep infinity\n' > bin/run_discord",
            "chmod 755 bin/run_discord"
        ]
    }
}

resource "scaleway_ip" "discord" {
    server = "${scaleway_server.discord.id}"
}

output "public_ip" {
    value = "${scaleway_ip.discord.ip}"
}
