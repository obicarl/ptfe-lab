##############################################################################
# Private Terraform Enterprise Server
# Sets up a RHEL instance for runnning Private Terraform Enterprise
##############################################################################

resource "aws_security_group" "ptfe_sg" {
  name        = "ptfe_server"
  description = "Allows inbound traffic from local subnets on default ports 80, 443, and 8080"
  vpc_id      = "${module.network_aws.vpc_id}"

  ingress {
    from_port   = "${var.ptfe_http_port}"
    to_port     = "${var.ptfe_http_port}"
    protocol    = "tcp"
    cidr_blocks = ["${module.network_aws.vpc_cidr}"]
  }

  ingress {
    from_port   = "${var.ptfe_https_port}"
    to_port     = "${var.ptfe_https_port}"
    protocol    = "tcp"
    cidr_blocks = ["${module.network_aws.vpc_cidr}"]
  }

  ingress {
    from_port   = "${var.ptfe_console_port}"
    to_port     = "${var.ptfe_console_port}"
    protocol    = "tcp"
    cidr_blocks = ["${module.network_aws.vpc_cidr}"]
  }

  ingress {
    from_port   = "${var.ptfe_lb_port}"
    to_port     = "${var.ptfe_lb_port}"
    protocol    = "tcp"
    cidr_blocks = ["${module.network_aws.vpc_cidr}"]
  }

  ingress {
    from_port   = "22"
    to_port     = "22"
    protocol    = "tcp"
    cidr_blocks = ["${module.network_aws.vpc_cidr}"]
  }

  ingress {
    from_port   = 8
    to_port     = 0
    protocol    = "icmp"
    cidr_blocks = ["${module.network_aws.vpc_cidr}"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["${module.network_aws.vpc_cidr}"]
  }
}

resource "aws_instance" "ptfe" {
  ami                    = "${var.ptfe_ami == "" ? data.aws_ami.rhel.id : var.ptfe_ami }"
  instance_type          = "t2.large"
  subnet_id              = "${module.network_aws.subnet_private_ids[0]}"
  key_name               = "${module.ssh-keypair-aws.name}"
  vpc_security_group_ids = ["${aws_security_group.ptfe_sg.id}"]

  root_block_device {
    volume_type           = "gp2"
    volume_size           = "50"
    delete_on_termination = "false"
  }

  tags {
    Name  = "${var.name}-ptfe"
    owner = "${var.tag_owner}"
    TTL   = "${var.tag_ttl}"
  }

  user_data = <<EOF
#!/bin/bash
hostnamectl set-hostname ptfe.${var.name}.${var.domain_name}
echo "proxy=http://proxy.${var.name}.${var.domain_name}:3128" >> /etc/yum.conf
sleep 60 # Allow the proxy to come up first
https_proxy=http://proxy.${var.name}.${var.domain_name}:3128 rpm -ivh https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
yum-config-manager --enable rhui-REGION-rhel-server-extras rhui-REGION-rhel-server-optional
yum install -y wget nmap vim-enhanced screen htop certbot
setenforce 0
perl -p -i -e 's/enforcing/disabled/g' /etc/selinux/config
EOF
}

resource "aws_route53_record" "ptfe" {
  zone_id = "${var.zone_id}"
  name    = "ptfe.${var.name}.${var.domain_name}"
  type    = "A"
  ttl     = "30"
  records = ["${aws_instance.ptfe.private_ip}"]
}
