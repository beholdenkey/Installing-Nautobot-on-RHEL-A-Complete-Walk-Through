#!/bin/bash
#------------------------------------------------------------ #
# By @beholdenkey
# Compatible Operating systems: RHEL 8
# Script to install Nautobot -  RHEL 8
# This process is being used to Create a Virtual Machine to then export as an OVA for Production Deployments.
#------------------------------------------------------------- #
# Resources - 16 vCores 32 GiB RAM 250 GiB Storage
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
    net-tools \ # optional
    nano # optional

echo 'Install PostgreSQL13-Server Module'
dnf module install postgresql:13/server

echo 'Initializing Database'
postgresql-setup --initdb