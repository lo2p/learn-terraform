data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-kernel-*"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

locals {
  subnets = length(var.private_subnet_ids) > 0 ? var.private_subnet_ids : var.private_subnets
}

resource "aws_instance" "app" {
  count                       = var.instance_count
  ami                         = data.aws_ami.al2023.id
  instance_type               = var.instance_type
  subnet_id                   = element(local.subnets, count.index % length(local.subnets))
  vpc_security_group_ids      = [var.ec2_sg_id]
  associate_public_ip_address = false
  key_name                    = var.key_name

  user_data = <<-EOF
    #!/bin/bash
    set -euo pipefail
    dnf install -y python3
    mkdir -p /var/www/html
    echo "hello from $(hostname)" > /var/www/html/index.html
    cat >/opt/start.sh <<'SH'
    #!/bin/bash
    exec python3 -m http.server 8080 --directory /var/www/html
    SH
    chmod +x /opt/start.sh

    cat >/etc/systemd/system/tierapp.service <<'UNIT'
    [Unit]
    Description=Simple HTTP server
    After=network-online.target

    [Service]
    User=ec2-user
    ExecStart=/opt/start.sh
    Restart=always

    [Install]
    WantedBy=multi-user.target
    UNIT

    systemctl daemon-reload
    systemctl enable --now tierapp.service
  EOF

  tags = merge(var.tags, { Name = "${var.name_prefix}-app-${count.index}" })
}
