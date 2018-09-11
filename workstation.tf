##############################################################################
# Windows Workstation
# Builds a workstation for accessing machines on the private subnet
##############################################################################

resource "aws_security_group" "workstation_sg" {
  name        = "windows_workstation"
  description = "Allows RDP traffic to the workstation on port 3389"
  vpc_id      = "${module.network_aws.vpc_id}"

  ingress {
    from_port   = 3389
    to_port     = 3389
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "workstation" {
  ami                    = "${var.workstation_ami == "" ? data.aws_ami.windows.id : var.workstation_ami }"
  instance_type          = "m5.xlarge"
  key_name               = "${module.ssh-keypair-aws.name}"
  subnet_id              = "${module.network_aws.subnet_public_ids[0]}"
  vpc_security_group_ids = ["${aws_security_group.workstation_sg.id}"]

  tags {
    Name  = "${var.name}-workstation"
    owner = "${var.tag_owner}"
    TTL   = "${var.tag_ttl}"
  }

  user_data = <<EOF
<powershell>
# h4x0r the Admin password
$admin = [adsi]("WinNT://./administrator, user")
$admin.psbase.invoke("SetPassword", "${var.workstationpw}")
Set-ExecutionPolicy Bypass -Scope Process -Force; iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))

# Turn off the evil Antimalware CPU hog
Set-MpPreference -DisableRealtimeMonitoring $true

# Install some packages, spruce the place up a bit
choco install cmder -y
choco install git -y
choco install nmap -y
choco install 7zip -y
choco install putty -y
choco install openssh -y
choco install winscp -y
choco install visualstudiocode -y
choco install googlechrome -y

# Create a Desktop shortcut for Cmder
# Note: Set your default shell to Powershell the first time you run this.
$TargetFile = "C:\tools\cmder\Cmder.exe"
$ShortcutFile = "C:\Users\Administrator\Desktop\cmder.lnk"
$WScriptShell = New-Object -ComObject WScript.Shell
$Shortcut = $WScriptShell.CreateShortcut($ShortcutFile)
$Shortcut.TargetPath = $TargetFile
$Shortcut.Save()

# Put the ssh private key into ~/.ssh
mkdir C:\Users\Administrator\.ssh
$sshkey = "${module.ssh-keypair-aws.private_key_pem}"
[System.IO.File]::WriteAllLines("C:\Users\Administrator\.ssh\id_rsa", $sshkey)

# Make a Putty ppk format copy of the ssh key
& 'C:\Program Files (x86)\WinSCP\WinSCP.com' /keygen C:\Users\Administrator\.ssh\id_rsa /output=C:\Users\Administrator\.ssh\id_rsa.ppk

# Configure the ~/.ssh/config file for short hostnames
$sshconfig = "
Host bitbucket
     HostName bitbucket.${var.name}.${var.domain_name}
     User ec2-user

Host proxy
     HostName proxy.${var.name}.${var.domain_name}
     User ec2-user

Host ptfe
     HostName ptfe.${var.name}.${var.domain_name}
     User ec2-user
"
[System.IO.File]::WriteAllLines("C:\Users\Administrator\.ssh\config", $sshconfig)

# Ditch the AWS shortcuts on the desktop
rm 'C:\Users\Administrator\Desktop\EC2 Feedback.website'
rm 'C:\Users\Administrator\Desktop\EC2 Microsoft Windows Guide.website'

</powershell>
EOF
}
