# Security Technical Implementation Guide

The Security Technical Implementation Guide (STIG) for RHEL 8 will be implemented using the RHEL 8 STIG ansible playbook.

PLEASE READ:

- How long will it take to execute this playbook?
  - It will take 20-30 minutes to execute this playbook.
- What will this playbook not do?
  - This playbook will not partition the drives in the required manner. The engineer must do this in the initial build phase.

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

```bash
mkdir /etc/ansible/playbooks
```

```bash
cd /etc/ansible/playbooks
```

```bash
git clone https://github.com/RedHatGov/rhel8-stig-latest 
```

Now that all of the staging and prerequisites have been taken care of and you have performed your checks we can not stop the services running the server. In the case of Nautobot we will be performing the following.

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

After functionality of all services and dependencies has been confirmed you can then proceed to go attempt to access the Nautobot instance.

Post Security Implementation Nautobot Management:

As many of you know, implementing a STIG changes many aspects of how a system performs or, more appropriately, what it doesn't function. With that being said, even though we did the right thing and created a system account for nautobot, allowing us to use the nautobot-server, you may notice that after the stig is implemented, you can no longer use the nautobot-server commands.
![Operation Not Permitted](https://github.com/beholdenkey/Installing-Nautobot-on-RHEL-A-Complete-Walk-Through/blob/main/Resources/Images/nautobot-server_operation_not_permitted.PNG)

Solution:

>Note: As of right now, this is the best solution I have found that doesn't result in altering SELinux rules or the STIG.

```bash
# Account with administrator privileges
su root
```

```bash
source /opt/nautobot/bin/activate
```

Then perform the following to verify functionality

```bash
nautobot-server check
```
