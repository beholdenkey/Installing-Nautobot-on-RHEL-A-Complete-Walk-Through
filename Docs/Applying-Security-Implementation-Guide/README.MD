# Security Technical Implementation Guide

The Security Technical Implementation Guide (STIG) for RHEL 8 will be implemented using the RHEL 8 STIG ansible-playbook.

> PLEASE READ:
>
> - This guide will only go over how to apply the STIG on RHEL 8
> - How long will it take to execute this playbook?
>   - It will take 20-30 minutes to execute this playbook.
> - What will this playbook not do?
>   - This playbook will not partition the drives in the required manner. The engineer must do this in the initial build phase.
>
> Note: If there are any issues with this playbook please submit the issue to <https://github.com/RedHatGov/rhel8-stig-latest>.

## Required Resources

- [Red Hat STIG Role](<https://galaxy.ansible.com/redhatofficial/rhel8_stig>)

- [Red Hat Compliance as Code RHEL 8 Playbook](<https://github.com/RedHatGov/rhel8-stig-latest>)

## Pre-Requisites

If you have not done so already you will need to install ``git``.

```bash
dnf -y install git
```

If you followed the Enterprise Nautobot Installation Guide, you should have already enabled the ansible content for your RHEL 8 server; however, if you have not, please perform the following commands.

```bash
sudo subscription-manager repos --enable ansible-2.9-for-rhel-8-x86_64-rpms
```

```bash
dnf -y install ansible
```

## Configuring Ansible Host File

Make the following changes to the ``hosts`` file in the  ``/ect/ansible`` dir. 

```yaml
# This is the default ansible 'hosts' file.
#
# It should live in /etc/ansible/hosts
#
#   - Comments begin with the '#' character
#   - Blank lines are ignored
#   - Groups of hosts are delimited by [header] elements
#   - You can enter hostnames or ip addresses
#   - A hostname/ip can be a member of multiple groups

# Ex 1: Ungrouped hosts, specify before any group headers:
[Ungrouped]
127.0.0.1 ansible_connection=local
```

>This will allow you to execute the playbook locally.

## Install Ansible role

```bash
ansible-galaxy install redhatofficial.rhel8_stig
```

## Download STIG Playbook

```bash
mkdir /etc/ansible/playbooks
```

```bash
cd /etc/ansible/playbooks
```

```bash
git clone https://github.com/RedHatGov/rhel8-stig-latest 
```

**PLEASE READ:**
If you wish to have a nautobot installation that you can upgrade and or make changes in the future, you will need to disable the FIPS Implementation portion of the STIG. This is because Nautobot relies on the python md5 hashlib, per [FIPS 140-2](https://csrc.nist.gov/csrc/media/projects/cryptographic-module-validation-program/documents/security-policies/140sp2355.pdf) md5 is not an approved algorithm. As of the time of writing this, there is no known workaround.

Now that all of the staging and prerequisites have been taken care of and you have performed your checks, we can not stop the services running the server. In the case of Nautobot, we will be performing the following.

```bash
systemctl disable redis postgresql nautobot nautobot-worker nginx
```

Now you can execute the playbook

```bash
ansible-playbook /etc/ansible/playbooks/rhel8-stig-latest/rhel8-playbook-stig.yml
```

>Note: After the STIG playbook has completed you will then start all of these services and check them for functionality.

```bash
systemctl enable --now redis postgresql nautobot nautobot-worker nginx
```

Now that they are restarted you will need to verify there status.

```bash
systemctl is-active redis postgresql nautobot nautobot-worker nginx
```
