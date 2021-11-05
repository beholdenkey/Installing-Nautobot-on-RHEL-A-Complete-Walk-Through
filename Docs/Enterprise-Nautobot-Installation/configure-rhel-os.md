# Preparing Red Hat Enterprise Linux Operating System

Before we do anything else, we will need to perform the initial configurations, such as selecting the necessary language. The following steps will be changes that may be depending on your organization's policies; however, the partition changes are a hard requirement.

First, we will go to the installation destination and perform the necessary partitions.

Step 1: Go down to "Storage Configuration," and select custom, and then click done.

Step 2: Click the "Click here to create them automatically" If you do click create them automatically, you will need to go back and reduce the partition size of the other partitions to give yourself enough space to create the new ones. (From here, you will add in the additional data and system partitions)

Step 3: Create the following partitions.(For now, I will not have the ratios available)

```txt
DATA

- /var/log
- /var/log/audit
- /var/tmp

SYSTEM

- /tmp
- /var
```

Step 4: Got to the KDUMP and click disable

Step 5: Configure you Network and Hostname

Step 6: Connect to your Red Hat CDN

Step 7: Make your software selection (I normally select "Minimal Install")

Step 8: Setup your root and User Account

## Update Operating System and install System Packages

```bash
sudo dnf -y update && \
    dnf -y install \
    git \
    python39 \
    python39-devel \
    python39-pip \
    redis \
    nginx \
    openldap-devel \
    nano \
```

>Note: nano is optional however I like to have it because not everyone is a vim master.

Ansible is a requirement to install the role and execute the playbook

```bash
sudo subscription-manager repos --enable ansible-2.9-for-rhel-8-x86_64-rpms
```

```bash
dnf -y install ansible
```

## Enable FIPS

```bash
fips-mode-setup --enable
```

Be sure to reboot after FIPS has been enabled. You will have to disable this again later

### Configure Firewall

```bash
firewall-cmd --permanent --add-port=443/tcp
firewall-cmd --permanent --add-port=80/tcp

firewall-cmd --reload
```

## Add SELinux Rule

SELinux may be preventing the reverse proxy connection. You may need to allow HTTP network connections with the command setsebool -P httpd_can_network_connect 1. For further information, view the SELinux troubleshooting guide.

```bash
setsebool -P httpd_can_network_connect 1
```
