Remaining tasks
==========================
* Install Bitbucket (done)
* Install PTFE (done)
* Configure Bitbucket and PTFE (done)
  + LetsEncrypt for SSL certs (done)
  + Use the airgap installer (done)
* Snapshot AMIs and attempt to provision from them (tested w/ bitbucket)
* Create network diagram (done)
* Create breakfix scenarios
* Write up README.md
* Create slide deck

Extra notes
==========================
SELinux must be disabled or set to permissive.

install.sh and airgap bundle must both be present on PTFE machine

Also require an SSH key for working with Bitbucket server (can copy into ~/.ssh/id_dsa)

We might or might not need the BBS certs (fetch with winscp?).  Need to see if the root CA from LetsEncrypt will suffice.







Training Environment Contents
==========================
VPC
Windows 2016 workstation
subnet
security group
PTFE Linux instance
Linux instance for squid proxy
Linux instance for bitbucket server
SSL certificate
DNS hostname (matches SSL certificate)

Scenario/breakfix ideas
==========================
Everything but a bastion/ssh host on private network
Outbound access only through squid proxy
Install on RHEL 7.3, 7.4, 7.5+  (docker version, etc)
Installing software with yum through a proxy
Excluding bitbucket from the proxy
Self-signed certs
Firewall rules blocking access to things
IPtables is on and blocking traffic
SELinux is on
One of PTFE docker containers fails
Bitbucket is using an internally-generated (but legitimate) SSL certificate
Bitbucket is using a self-signed certificate
PTFE with self-signed certificate
PTFE with internally generated certificate
Airgap bundle installation

Network Diagram
==========================

```+----------------------------------------------------------------------------------------------------------------+
|                                                                                                                |
|  +----------------------------------------------------+    +------------------------------------------------+  |
|  |  ptfe.you.hashidemos.io                            |    |  proxy.you.hashidemos.io                       |  |
|  |  +--------------------+                            |    |  +--------------------+ +--------------------+ |  |
|  |  |                    |                            |    |  |                    | |                    | |  |
|  |  |                    |                            |    |  |                    | |                    | |  |
|  |  |  Open Ports:       |                            |    |  |                    | |   Windows          | |  |
|  |  |  22, 80, 8080, 443 |                            |    |  |                    | |   Workstation      | |  |
|  |  |                    +------------------------------------>    Squid Proxy     | |                    | |  |
|  |  |                    |                            |    |  |    on port 3128    | |   RDP on port 3389 | |  |
|  |  |                    |                            |    |  |                    | |                    | |  |
|  |  |                    |                            |    |  |                    | |                    | |  |
|  |  |                    |          +------------------------->                    | |                    | |  |
|  |  +--------------------+          |                 |    |  |                    | |                    | |  |
|  |                                  |                 |    |  +---------+----------+ +----------^---------+ |  |
|  |  bitbucket.you.hashidemos.io     |                 |    |            |                       | RDP       |  |
|  |  +--------------------+          |                 |    |            |                       |           |  |
|  |  |                    +----------+                 |    |            |                       |           |  |
|  |  |                    |                            |    |            |                       |           |  |
|  |  |  Open Ports:       |     PRIVATE SUBNETS        |    |            | PUBLIC SUBNETS        |           |  |
|  |  |  22, 80, 443       |     No Internet Access     |    |            | Unrestricted Outbound |           |  |
|  |  |                    |     Except through proxy   |    |            | Internet Access       |           |  |
|  |  |                    |     Only local traffic     |    |            | Can open to Internet  |           |  |
|  |  |                    |     172.19.48.0/20         |    |            | 172.19.0.0/20         |           |  |
|  |  |                    |     172.19.64.0/20         |    |            | 172.19.16.0/20        |           |  |
|  |  |                    |     172.19.80.0/20         |    |            | 172.19.32.0/20        |           |  |
|  |  +--------------------+                            |    |            |                       |           |  |
|  |                                                    |    |            |                       |           |  |
|  +----------------------------------------------------+    +------------------------------------------------+  |
|                                                                         |                       |              |
|                                              VPC: 172.19.0.0/16         |                       |              |
+----------------------------------------------------------------------------------------------------------------+
                                                    THE INTERNET          v                       +
```

Useful links
==========================

### Proxy Settings for BBS
https://confluence.atlassian.com/bitbucketserverkb/how-to-configure-an-outbound-http-and-https-proxy-for-bitbucket-server-779171680.html

### Bitbucket and PTFE config
https://www.terraform.io/docs/enterprise/vcs/bitbucket-server.html

### SSL Config for BBS
https://confluence.atlassian.com/bitbucketserver/securing-bitbucket-server-with-tomcat-using-ssl-776640127.html

### User feedback on PTFE issues
https://docs.google.com/document/d/1NmfKy-u47eo_2wSssQM0pml119PcxgRMy2P1nr1zOwM/edit

### Installing Bitbucket Trial
https://confluence.atlassian.com/bitbucketserver/install-a-bitbucket-server-trial-867192384.html

### Dealing with shitty proxy settings:
https://docs.docker.com/config/daemon/systemd/#httphttps-proxy

### Command to get the installer script
curl --proxy http://proxy.sean.hashidemos.io:3128 https://install.terraform.io/ptfe/stable > install.sh

LetsEncrypt Commands for BBS
==========================
### Step One: Generate a new SSL certificate
`https_proxy=http://proxy.sean.hashidemos.io:3128 certbot certonly --server https://acme-v02.api.letsencrypt.org/directory --manual --preferred-challenges dns-01 -d bitbucket.sean.hashidemos.io`

### Step Two: Convert the SSL cert into p12 format
`openssl pkcs12 -export -name bitbucket.sean.hashidemos.io -in /etc/letsencrypt/live/bitbucket.sean.hashidemos.io/fullchain.pem -inkey /etc/letsencrypt/live/bitbucket.sean.hashidemos.io/privkey.pem -out /root/keystore.p12`

### Step Three: Convert the SSL cert into Java Key Store (jks) format
`/opt/atlassian/bitbucket/5.12.0/jre/bin/keytool -importkeystore -destkeystore /var/atlassian/application-data/bitbucket/shared/config/ssl-keystore.jks -srckeystore /root/keystore.p12 -srcstoretype pkcs12 -alias bitbucket.sean.hashidemos.io`

Bitbucket Proxy Configuration
==========================
Open the file /opt/atlassian/bitbucket/5.12.0/bin/_start-webapp.sh and look for the 
line containing JVM_SUPPORT_RECOMMENDED_ARGS.  Uncomment it and make it look like this:

`JVM_SUPPORT_RECOMMENDED_ARGS="-Dhttps.proxyHost=proxy.sean.hashidemos.io -Dhttps.proxyPort=3128 -Dhttp.nonProxyHosts=ptfe.sean.hashidemos.io"`

Restart bitbucket:
`/etc/init.d/atlbitbucket restart`

LetsEncrypt commands for PTFE
==========================
`https_proxy=http://proxy.sean.hashidemos.io:3128 certbot certonly --server https://acme-v02.api.letsencrypt.org/directory --manual --preferred-challenges dns-01 -d ptfe.sean.hashidemos.io`