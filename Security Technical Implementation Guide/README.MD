# Security Technical Implementation Guide

The Security Technical Implementation Guide (STIG) for RHEL 8 will be implemented using the RHEL 8 STIG ansible playbook.

>Note: If there are any issues with this playbook please submit the issue to <https://github.com/RedHatGov/rhel8-stig-latest>.

Resources:

<https://galaxy.ansible.com/redhatofficial/rhel8_stig>

<https://github.com/RedHatGov/rhel8-stig-latest>

Step 1:

```bash
dnf -y update && \
dnf -y install \
python39 \
python39-devel \
python39-pip \
git
```

```bash
mkdir /etc/ansible
```

```bash
cd /etc/ansible
```

>Note: You will still need to add everything to the ansible.cfg the best way to do this is either to git clone this repo or if you are able then copy and paste 
from this repo. (It cannot be left blank)

```bash
touch ansible.cfg
```

>Note: You will still need to add "127.0.0.1 ansible_connection=local" to the host file to run the playbook locally.

```bash
touch hosts
```

```bash
pip3 install ansible
```

```bash
ansible-galaxy install redhatofficial.rhel8_stig
```

>Note: You may want to create a folder for your playbooks, this way you can find them and remove them after you are done using them.

```bash
git clone https://github.com/RedHatGov/rhel8-stig-latest
```