#!/bin/bash
#------------------------------------------------------------ #
# By @beholdenkey
# Compatible Operating systems: RHEL 8
# Script to install Nautobot -  RHEL 8
# This process is being used to Create a Virtual Machine to then export as an OVA for Production Deployments.
#------------------------------------------------------------- #
# Leave the Host Name as the default (localhost.localdomain) this can be changed as needed later.
# It is important to remember that you need to remove all Network Configurations prior to exporting as an OVA
# The DISA STIG for Red Hat Enterprise LInux - Will be applied so be sure to correctly partition the storage
# Note this script is still a work in progress.
echo 'Updating OS and Installing System Packages'

sudo dnf -y update && \
    dnf -y install \
    git \
    python39 \
    python39-devel \
    python39-pip \
    redis \
    nano

echo 'Installing Ansible'
pip3 install wheel
pip3 install ansible

echo 'Exposing port 443'
firewall-cmd --permanent --add-port=443/tcp
firewall-cmd --permanent --add-port=80/tcp
echo 'Reloading firewall'
firewall-cmd --reload

# SELinux may be preventing the reverse proxy connection. You may need to allow HTTP network connections with the command setsebool -P httpd_can_network_connect 1. For further information, view the SELinux troubleshooting guide.
echo 'Adding SELinux Rule to Allow HTTP network connections through Reverse Proxy'
setsebool -P httpd_can_network_connect 1

echo 'Install PostgreSQL13-Server Module'
dnf -y module install postgresql:13/server

echo 'Initializing Database'
postgresql-setup --initdb

# Be Sure to go to the \Installing-Nautobot-on-RHEL---A-Complete-Walk-Through\Resources\PostgreSQL\Templates and modify the templates how you see fit.
# If you make any changes to the file paths be sure to alter the script accordingly.

echo 'Copying pg_hba.conf to /var/lib/pgsql/data/pg_hba.conf'

# Place Holder

echo 'Copying postgresql.conf to /var/lib/pgsql/data/postgresql.conf'

# Place Holder

echo 'Enable Postgresql Service'
systemctl enable --now postgresql

echo 'Enable Redis'
sudo systemctl enable --now redis

echo 'Test Redis'
redis-cli ping

echo 'Redis Status'
systemctl is-active redis

echo 'Create a system user account named nautobot. This user will own all of the Nautobot files, and the Nautobot web services will be configured to run under this account.
The following command also creates the /opt/nautobot directory and sets it as the home directory for the user.'
sudo useradd --system --shell /bin/bash --create-home --home-dir /opt/nautobot nautobot

echo 'Create the Virtual Environment'
sudo -u nautobot python3 -m venv /opt/nautobot

echo "export NAUTOBOT_ROOT=/opt/nautobot" | sudo tee -a ~nautobot/.bashrc

echo 'Changing to Nautobot User'
#These following commands must be executed as the nautobot user
sudo -iu nautobot

echo 'Python Wheel Package'
pip3 install --upgrade pip wheel

echo 'Install Nautobot Python Package'
pip3 install nautobot

echo 'Server Init'
nautobot-server init


pip3 install nautobot_data_validation_engine nautobot_netbox_importer nautobot_plugin_nornir nautobot_golden_config

cd /opt/nautobot

touch local_requirements.txt

pip3 install -r $NAUTOBOT_ROOT/local_requirements.txt

echo nautobot_data_validation_engine >> $NAUTOBOT_ROOT/local_requirements.txt
echo nautobot_netbox_importer >> $NAUTOBOT_ROOT/local_requirements.txt
echo nautobot_plugin_nornir >> $NAUTOBOT_ROOT/local_requirements.txt
echo nautobot_golden_config >> $NAUTOBOT_ROOT/local_requirements.txt

nautobot-server migrate

nautobot-server createsuperuser

nautobot-server collectstatic

echo 'Obtain an SSL Certificate'
sudo openssl req -x509 -nodes -days 365 -newkey rsa:4096 \
  -keyout /etc/pki/tls/private/nautobot.key \
  -out /etc/pki/tls/certs/nautobot.crt

echo 'Install Nginx'
dnf -y install Nginx

echo 'Copy Nautobot.conf to /etc/nginx/conf.d'

#PLACE HOLDER

sudo sed -i 's@ default_server@@' /etc/nginx/nginx.conf