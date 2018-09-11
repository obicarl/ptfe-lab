variable "create" {}
variable "name" {}
variable "create_vpc" {}
variable "rsa_bits" {}
variable "vpc_cidr" {}

variable "vpc_cidrs_public" {
  type = "list"
}

variable "nat_count" {}

variable "vpc_cidrs_private" {
  type = "list"
}

variable "release_version" {}
variable "consul_version" {}
variable "vault_version" {}
variable "nomad_version" {}
variable "os" {}
variable "os_version" {}
variable "bastion_count" {}
variable "instance_type" {}

variable "tag_ttl" {}

variable "tag_owner" {}

# These are only for the bastion host
variable "tags" {
  type = "map"
}

variable "rhel_version" {
  default = "7.5"
}

variable "bbs_http_port" {
  default = "7990"
}

variable "bbs_https_port" {
  default = "8443"
}

variable "bbs_ssh_port" {
  default ="7999"
}

variable "ptfe_http_port" {
  default = "80"
}

# Currently unused but could be configured with an AWS ELB
variable "ptfe_lb_port" {
  default = "8080"
}

variable "ptfe_https_port" {
  default = "443"
}

variable "ptfe_console_port" {
  default = "8800"
}

variable "workstationpw" {}

variable "workstation_ami" {}

variable "bitbucket_ami" {}

variable "ptfe_ami" {}

variable "squidproxy_ami" {}

variable "zone_id" {
  default = "Z2VGUC188F45PC"
}

variable "domain_name" {
  default = "hashidemos.io"
}

variable "bbs_download_url" {
  default = "https://www.atlassian.com/software/stash/downloads/binary/atlassian-bitbucket-5.12.0-x64.bin"
}

variable "bbs_filename" {
  default = "atlassian-bitbucket-5.12.0-x64.bin"
}

variable "git_download_url" {
  default = "https://mirrors.edge.kernel.org/pub/software/scm/git/git-2.9.5.tar.gz"
}

variable "git_directory_name" {
  default = "git-2.9.5"
}
