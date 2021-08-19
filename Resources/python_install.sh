#!/bin/bash
#------------------------------------------------------------ #
# By @beholdenkey
# Compatible Operating systems: Centos 8 Stream, RHEL 8
# Script to install Python 3.9.6 on CentOS 8 Stream and RHEL 8
#------------------------------------------------------------- #

sudo dnf -y update && \
    dnf -y install \
    openssl-devel \
    libffi-devel \ 
    bzip2-devel \
    wget && \
dnf groupinstall "Development Tools" -y

wget https://www.python.org/ftp/python/3.9.6/Python-3.9.6.tgz

tar xvf Python-3.9.6.tgz

cd Python-3.9*/

./configure --enable-optimizations

sudo make altinstall

PATH=”$PATH:/usr/local/bin/python”

rm -rf Python-3.9.6.tgz
rm -rf Python-3.9.6
 
python3.9 --version
