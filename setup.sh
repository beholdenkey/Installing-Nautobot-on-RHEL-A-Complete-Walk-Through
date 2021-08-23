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

echo 'Updating OS and Installing System Packages'

sudo dnf -y update && \
    dnf -y install \
    git \
    python39 \
    python39-devel \
    python39-pip \
    redis \
#    net-tools \ # optional
#    nano # optional

echo 'Installing Ansible'
pip3 install ansible

echo 'Exposing port 443'
firewall-cmd --permanent --add-port=443/tcp
echo 'Reloading firewall'
firewall-cmd --reload

# SELinux may be preventing the reverse proxy connection. You may need to allow HTTP network connections with the command setsebool -P httpd_can_network_connect 1. For further information, view the SELinux troubleshooting guide.
echo 'Adding SELinux Rule to Allow HTTP network connections through Reverse Proxy'
setsebool -P httpd_can_network_connect 1

echo 'Install PostgreSQL13-Server Module'
dnf module install postgresql:13/server

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