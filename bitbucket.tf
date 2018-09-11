##############################################################################
# Bitbucket Server
# Sets up a RHEL instance for runnning Bitbucket Server
##############################################################################

resource "aws_security_group" "bitbucket_sg" {
  name        = "bitbucket_server"
  description = "Allows inbound traffic from local subnets on default ports 80 and 443"
  vpc_id      = "${module.network_aws.vpc_id}"

  ingress {
    from_port   = "${var.bbs_http_port}"
    to_port     = "${var.bbs_http_port}"
    protocol    = "tcp"
    cidr_blocks = ["${module.network_aws.vpc_cidr}"]
  }

  ingress {
    from_port   = "${var.bbs_https_port}"
    to_port     = "${var.bbs_https_port}"
    protocol    = "tcp"
    cidr_blocks = ["${module.network_aws.vpc_cidr}"]
  }

  ingress {
    from_port   = "${var.bbs_ssh_port}"
    to_port     = "${var.bbs_ssh_port}"
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

resource "aws_instance" "bitbucket" {
  ami                    = "${var.bitbucket_ami == "" ? data.aws_ami.rhel.id : var.bitbucket_ami }"
  instance_type          = "t2.medium"
  subnet_id              = "${module.network_aws.subnet_private_ids[0]}"
  key_name               = "${module.ssh-keypair-aws.name}"
  vpc_security_group_ids = ["${aws_security_group.bitbucket_sg.id}"]

  tags {
    Name  = "${var.name}-bitbucket"
    owner = "${var.tag_owner}"
    TTL   = "${var.tag_ttl}"
  }

  user_data = <<EOF
#!/bin/bash
hostnamectl set-hostname bitbucket.${var.name}.${var.domain_name}
echo "proxy=http://proxy.${var.name}.${var.domain_name}:3128" >> /etc/yum.conf
sleep 60 # Allow the proxy to come up first
https_proxy=http://proxy.${var.name}.${var.domain_name}:3128 rpm -ivh https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
yum-config-manager --enable rhui-REGION-rhel-server-extras rhui-REGION-rhel-server-optional
yum install -y wget nmap vim-enhanced screen git make gcc zlib-devel perl-devel certbot htop
cd /root
https_proxy=http://proxy.${var.name}.${var.domain_name}:3128 wget ${var.bbs_download_url}
chmod 755 ${var.bbs_filename}
https_proxy=http://proxy.${var.name}.${var.domain_name}:3128 wget ${var.git_download_url}
tar -zxvf ${var.git_directory_name}.tar.gz
cd ${var.git_directory_name}
./configure && make && make install
cat <<PROPS > /root/bitbucket.properties
server.port=8443
server.ssl.enabled=true
server.ssl.key-store=/var/atlassian/application-data/bitbucket/shared/config/ssl-keystore.jks
server.ssl.key-store-password=CHANGEME
server.ssl.key-password=CHANGEME
server.ssl.key-alias=bitbucket.${var.name}.${var.domain_name}
PROPS
echo "User data script completed successfully.  You may proceed with installing Bitbucket Server." > /root/USERDATA_FINISHED.txt
EOF
}

resource "aws_route53_record" "bitbucket" {
  zone_id = "${var.zone_id}"
  name    = "bitbucket.${var.name}.${var.domain_name}"
  type    = "A"
  ttl     = "30"
  records = ["${aws_instance.bitbucket.private_ip}"]
}
