#!/bin/bash

# cyberscript yay!

# check if sudo was used
if [ "$EUID" -ne 0 ]; then
    echo "Please run as root"
    exit
fi

echo "Starting script..."

# Updating sutff
echo "Updating"
apt update && apt upgrade -y && apt dist-upgrade -y

# Install security packages
echo "Installing essential security packages..."
apt install -y ufw fail2ban clamav clamtk rkhunter chkrootkit lynis gufw unattended-upgrades apt-listchanges auditd apparmor apparmor-profiles apparmor-utils clamav-daemon

# Enable and configure UFW firewall
echo "Enabling firewall..."
ufw default deny incoming
ufw default allow outgoing
ufw enable
ufw status verbose

# Enable automatic updates
echo "Enabling automatic updates…"
dpkg-reconfigure -plow unattended-upgrades

# Configuring fail2ban
echo "Configuring Fail2Ban…"
cat <<EOF > /etc/fail2ban/jail.local
[DEFAULT]
bantime = 1h
findtime = 10m
maxretry = 3

[sshd]
enabled = true
EOF
systemctl enable fail2ban
systemctl restart fail2ban

# SSH Hardening
echo "Securing SSH..."
sed -i 's/#PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
sed -i 's/#X11Forwarding yes/X11Forwarding no/' /etc/ssh/sshd_config
sed -i 's/#MaxAuthTries.*/MaxAuthTries 3/' /etc/ssh/sshd_config
echo "AllowUsers your_username" >> /etc/ssh/sshd_config # replace 'your_username' with your actual username
systemctl restart sshd

# Disable unnecessary services 
echo "Disabling unnecessary services…"
systemctl disable avahi-daemon cups bluetooth
systemctl stop avahi-daemon cups bluetooth

# Set up ClamAV 
echo "Setting up ClamAV…"
systemctl enable clamav-freshclam
systemctl start clamav-freshclam
freshclam
systemctl enable clamav-daemon
systemctl start clamav-daemon
clamscan --infected --remove --recursive /home

# Enable daily scans
echo "Setting up daily malware scans with ClamAV..."
echo "0 3 * * * root clamscan -r / --remove --quiet" >> /etc/crontab

# Set up auditd for system monitoring 
echo "Configuring auditd…"
systemctl enable auditd
systemctl start auditd

# AppArmor hardening
echo "Configuring AppArmor…"
aa-enforce /etc/apparmor.d/*

# Set password policies
echo "Enforcing strong password policies..."
apt install -y libpam-pwquality
echo "password requisite pam_pwquality.so retry=3 minlen=12 difok=3 ucredit=-1 lcredit=-1 dcredit=-1 ocredit=-1" >> /etc/pam.d/common-password

# Secure kernel parameters
echo "Applying secure kernel parameters..."
cat <<EOF >> /etc/sysctl.conf

# Disable IP source routing
net.ipv4.conf.all.accept_source_route = 0
net.ipv4.conf.default.accept_source_route = 0

# Enable IP spoofing protection
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1

# Disable ICMP redirects
net.ipv4.conf.all.accept_redirects = 0
net.ipv6.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0

# Enable TCP SYN Cookies
net.ipv4.tcp_syncookies = 1
EOF

sysctl -p

# Disable unused filesystems 
echo "Disabling unused filesystems..."
echo "install cramfs /bin/false" >> /etc/modprobe.d/disable-filesystems.conf
echo "install freevxfs /bin/false" >> /etc/modprobe.d/disable-filesystems.conf
echo "install jffs2 /bin/false" >> /etc/modprobe.d/disable-filesystems.conf
echo "install hfs /bin/false" >> /etc/modprobe.d/disable-filesystems.conf
echo "install hfsplus /bin/false" >> /etc/modprobe.d/disable-filesystems.conf
echo "install squashfs /bin/false" >> /etc/modprobe.d/disable-filesystems.conf
echo "install udf /bin/false" >> /etc/modprobe.d/disable-filesystems.conf



# Remove unnecessary packages to minimize vulnerabilities
echo "Removing unnecessary packages..."
apt autoremove -y

# Rootkit detection
echo "Running rootkit checks with rkhunter and chkrootkit..."
rkhunter --update
rkhunter --checkall --skip-keypress
chkrootkit

# Perform a Lynis security audit for additional recommendations
echo "Running Lynis security audit..."
lynis audit system

echo "Script finished. Don’t forget to check users, apps, etc.”
