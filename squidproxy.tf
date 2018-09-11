##############################################################################
# Squid Proxy Server
# Sets up a RHEL instance for runnning a Squid proxy, NTP and DNS
##############################################################################

resource "aws_security_group" "squid_proxy_sg" {
  name        = "squid_proxy_server"
  description = "Allows all inbound traffic from local subnets"
  vpc_id      = "${module.network_aws.vpc_id}"

  # Allow all inbound from local subnets
  ingress {
    from_port   = "0"
    to_port     = "0"
    protocol    = "-1"
    cidr_blocks = ["${module.network_aws.vpc_cidr}"]
  }

  # Allow all outbound traffic
  egress {
    from_port   = "0"
    to_port     = "0"
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "squid_proxy" {
  ami                    = "${var.squidproxy_ami == "" ? data.aws_ami.rhel.id : var.squidproxy_ami }"
  instance_type          = "t2.micro"
  subnet_id              = "${module.network_aws.subnet_public_ids[0]}"
  key_name               = "${module.ssh-keypair-aws.name}"
  vpc_security_group_ids = ["${aws_security_group.squid_proxy_sg.id}"]

  tags {
    Name  = "${var.name}-squidproxy"
    owner = "${var.tag_owner}"
    TTL   = "${var.tag_ttl}"
  }

  user_data = <<EOF
#!/bin/bash
hostnamectl set-hostname proxy.${var.name}.${var.domain_name}
yum install -y squid
systemctl start squid
systemctl enable squid.service
EOF
}

resource "aws_route53_record" "proxy" {
  zone_id = "${var.zone_id}"
  name    = "proxy.${var.name}.${var.domain_name}"
  type    = "A"
  ttl     = "30"
  records = ["${aws_instance.squid_proxy.private_ip}"]
}
