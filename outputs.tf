output "zREADME" {
  value = <<README

##############################################################################
# Your PTFE lab infrastructure has been successfully provisioned!
# Follow the instructions below to finish setting up Bitbucket Server.

##############################################################################
# Install Bitbucket
SSH to the bitbucket server, get a root shell and run the bitbucket installer.
You can leave all the settings at their defaults.

sudo /bin/su - root
./atlassian-bitbucket-5.12.0-x64.bin

After Bitbucket has started, visit this URL to complete the installation 
wizard:

http://bitbucket.${var.name}.${var.domain_name}:7990

During the installation you'll be prompted to create an Atlassian account and
fetch an evaluation license. Follow the steps below to enable proxy access to
the Internet (for installing plugins) and SSL encryption.

##############################################################################
# Configure Bitbucket to use the proxy

Open the file /opt/atlassian/bitbucket/5.12.0/bin/_start-webapp.sh and look for the 
line containing JVM_SUPPORT_RECOMMENDED_ARGS. Uncomment it and make it look like this:

JVM_SUPPORT_RECOMMENDED_ARGS="-Dhttps.proxyHost=proxy.${var.name}.${var.domain_name} -Dhttps.proxyPort=3128 -Dhttp.nonProxyHosts=ptfe.${var.name}.${var.domain_name}"

##############################################################################
# Use LetsEncrypt's certbot to generate an SSL certificate for Bitbucket

# Step One: Generate a new SSL certificate
https_proxy=http://proxy.${var.name}.${var.domain_name}:3128 certbot certonly --server https://acme-v02.api.letsencrypt.org/directory --manual --preferred-challenges dns-01 -d bitbucket.${var.name}.${var.domain_name}

# Step Two: Create a DNS TXT record to verify your SSL cert
You will do this part in the AWS Route 53 console. Log onto the Route 53
control panel and navigate into the ${var.domain_name} zone. You should wrap the 
data of the TXT record in quotation marks when you create it, and set the TTL
to 30 seconds. Give it a minute or two before you proceed with the
verification, or the DNS record may not have propagated yet.

# Step Three: Convert the SSL cert into p12 format
openssl pkcs12 -export -name bitbucket.${var.name}.${var.domain_name} -in /etc/letsencrypt/live/bitbucket.${var.name}.${var.domain_name}/fullchain.pem -inkey /etc/letsencrypt/live/bitbucket.${var.name}.${var.domain_name}/privkey.pem -out /root/keystore.p12

# Step Four: Convert the SSL cert into Java Key Store (jks) format
/opt/atlassian/bitbucket/5.12.0/jre/bin/keytool -importkeystore -destkeystore /var/atlassian/application-data/bitbucket/shared/config/ssl-keystore.jks -srckeystore /root/keystore.p12 -srcstoretype pkcs12 -alias bitbucket.${var.name}.${var.domain_name}

# Step Five: Edit and copy the bitbucket.properties file
vim /root/bitbucket.properties
cp /root/bitbucket.properties /var/atlassian/application-data/bitbucket/shared/bitbucket.properties

# Step Six: Restart Bitbucket server to activate SSL on port 8443
/etc/init.d/atlbitbucket restart

# Step Seven: Log onto the UI at https://bitbucket.${var.name}.${var.domain_name}:8443 
and fix the "Base URL Mismatch" error. This will update all the links on your 
BBS instance to use the new SSL settings.

##############################################################################
# Use LetsEncrypt's certbot to generate an SSL certificate for PTFE

# Step One: Generate a new SSL certificate
https_proxy=http://proxy.${var.name}.${var.domain_name}:3128 certbot certonly --server https://acme-v02.api.letsencrypt.org/directory --manual --preferred-challenges dns-01 -d ptfe.${var.name}.${var.domain_name}

# Step Two: Create a DNS TXT record to verify your SSL cert
Follow the same process that you did for the Bitbucket cert.

# Step Three: Copy your SSL certs into the ec2 user's home directory
cp -rL /etc/letsencrypt/live/ptfe.${var.name}.hashidemos.io /home/ec2-user/

# Step Four: Use the scp command (from your workstation) to copy the certs
scp -r ptfe:~/ptfe.${var.name}.hashicorp-success.com C:\Users\Administrator\Desktop

##############################################################################
# Run Inspec to do the pre-flight checks on your PTFE server
inspec exec ptfe-preflight-check -t ssh://ec2-user@ptfe.${var.name}.hashidemos.io -i ~/.ssh/id_rsa --sudo

##############################################################################
# Use the following VPC and subnet ID for the exercises in chapter 6
vpc_id = ${module.network_aws.vpc_id}
subnet_id = ${module.network_aws.subnet_public_ids[0]}

##############################################################################
# Workstation Credentials

Workstation: ${aws_instance.workstation.public_dns}
Username: Administrator
Password: ${var.workstationpw}

Once you have logged onto the workstation, you may SSH to the other instances
using the short hostname. For example:

ssh ptfe
ssh bitbucket

README
}
