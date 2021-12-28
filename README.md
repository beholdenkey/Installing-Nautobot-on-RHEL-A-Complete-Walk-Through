# Installing Nautobot on Red Hat Enterprise Linux: A Complete Walk Through

## Table of Contents

- [Installing Nautobot on Red Hat Enterprise Linux: A Complete Walk Through](#installing-nautobot-on-red-hat-enterprise-linux-a-complete-walk-through)
  - [Table of Contents](#table-of-contents)
  - [Synopsis](#synopsis)
  - [Dependencies](#dependencies)
    - [Mandatory dependencies](#mandatory-dependencies)
  - [Server Requirements](#server-requirements)
  - [Preparing Operating System](#preparing-operating-system)
    - [Update Operating System and install System Packages](#update-operating-system-and-install-system-packages)
    - [Configure Firewall](#configure-firewall)
    - [Add SELinux Rule](#add-selinux-rule)
    - [Configure PostgreSQL Database](#configure-postgresql-database)
      - [Start PostgreSQL](#start-postgresql)
      - [Create a Database](#create-a-database)
      - [Verify PostgreSQL Service Availability](#verify-postgresql-service-availability)
  - [Setup Redis](#setup-redis)
    - [Install and Configure Nautobot](#install-and-configure-nautobot)
    - [Configure Nautobot Account and Environment](#configure-nautobot-account-and-environment)
    - [Install Nautobot](#install-nautobot)
  - [Deploying Nautobot Web Service and Workers](#deploying-nautobot-web-service-and-workers)
    - [Nautobot Service](#nautobot-service)
    - [Nautobot Worker Service](#nautobot-worker-service)
      - [Configure Systemd for new Services](#configure-systemd-for-new-services)
    - [Configure HTTP Server](#configure-http-server)
  - [Applying DISA Security Technical Implementation Guide to Nautobot](#applying-disa-security-technical-implementation-guide-to-nautobot)
  - [Required Resources](#required-resources)
  - [Pre-Requisites](#pre-requisites)
  - [Configuring Ansible Host File](#configuring-ansible-host-file)
  - [Install Ansible role](#install-ansible-role)
  - [Download STIG Playbook](#download-stig-playbook)
  - [Upgrading a Disconnected Nautobot Server](#upgrading-a-disconnected-nautobot-server)
    - [Normal Nautobot Upgrade](#normal-nautobot-upgrade)
    - [Update Prerequisites to Required Versions](#update-prerequisites-to-required-versions)
    - [Install the Latest Release](#install-the-latest-release)
    - [Upgrade your Optional Dependencies](#upgrade-your-optional-dependencies)
    - [Run the Post Upgrade Operations](#run-the-post-upgrade-operations)
    - [Restart the Nautobot Services](#restart-the-nautobot-services)
  - [Disconnected Nautobot Upgrade](#disconnected-nautobot-upgrade)
  - [Closing Comments](#closing-comments)
    - [Resources](#resources)

## Synopsis

This guide assists users in installing Nautobot on Red Hat Enterprise Linux. Although this installation guide focused on supporting organizations that require an increased standard of security, it can easily be forked and modified to support the needs of others. I will go through the process of installation, hardening, and STIG implementation. In addition, I will be using the ansible-playbook for the RHEL 8 STIG implementation. Please refer to the resources directory for the links to these repositories. Also, if you are not familiar with the dependencies of Nautobot, I highly recommend that you do some reading because nautobot consists of a rather diverse Application Stack.

## Dependencies

I have tested this build process on the following Operating Systems:

| Operating Systems        | Version                 |
| ------------------------ | ----------------------- |
| Red Hat Enterprise Linux | 8.1, 8.2, 8.3, 8.4, 8.5 |

### Mandatory dependencies

The following minimum versions are required for Nautobot to operate and the versions I have tested in production environments. I will not be using MySQL, so I will not be trying or going over that.

| Dependency | Role         | Minimum Version | Production Tested |
| ---------- | ------------ | --------------- | ----------------- |
| Python     | Application  | 3.6             | 3.9.7             |
| PostgreSQL | Database     | 9.6             | 13.2              |
| Redis      | Cache, Queue | 4.0             | 6.1               |

## Server Requirements

Minimum VM Resource Requirements:
>Note: These are the minimum requirements these are not the recommended requirements for a production environment.

- vCores - 4
- Memory - 8 GiB
- Storage - 125 GiB

## Preparing Operating System

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

### Update Operating System and install System Packages

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
    redis \
    nano
```

>Note: nano is optional however I like to have it because not everyone is a vim master.

Ansible is a requirement to install the role and execute the playbook

```bash
sudo subscription-manager repos --enable ansible-2.9-for-rhel-8-x86_64-rpms
```

```bash
dnf -y install ansible
```

### Configure Firewall

```bash
firewall-cmd --permanent --add-port=443/tcp
firewall-cmd --permanent --add-port=80/tcp

firewall-cmd --reload
```

### Add SELinux Rule

SELinux may be preventing the reverse proxy connection. You may need to allow HTTP network connections with the command setsebool -P httpd_can_network_connect 1. For further information, view the SELinux troubleshooting guide.

```bash
setsebool -P httpd_can_network_connect 1
```

### Configure PostgreSQL Database

Install PostgreSQL-Server Module

```bash
dnf -y module install postgresql:13/server
```

Initialize the Database

```bash
postgresql-setup --initdb
```

Configure Authentication

RHEL configures PostgreSQL to use ident host-based authentication by default. Because Nautobot will need to authenticate using a username and password, we must update pg_hba.conf to support scram-256 password authentication.

As root, edit `/var/lib/pgsql/data/postgresql.conf` and make the following changes.

Before:

```bash
# - Authentication -

#authentication_timeout = 1min  # 1s-600s
#password_encryption = md5  # md5 or scram-sha-256
#db_user_namespace = off

# GSSAPI using Kerberos
#krb_server_keyfile = 'FILE:${sysconfdir}/krb5.keytab'
#krb_caseins_users = off

# - SSL -

#ssl = off
#ssl_ca_file = ''
#ssl_cert_file = 'server.crt'
#ssl_crl_file = ''
#ssl_key_file = 'server.key'
#ssl_ciphers = 'HIGH:MEDIUM:+3DES:!aNULL' # allowed SSL ciphers
#ssl_prefer_server_ciphers = on
#ssl_ecdh_curve = 'prime256v1'
#ssl_min_protocol_version = 'TLSv1.2'
#ssl_max_protocol_version = ''
#ssl_dh_params_file = ''
#ssl_passphrase_command = ''
#ssl_passphrase_command_supports_reload = off
```

After:

```bash
# - Authentication -

#authentication_timeout = 1min  # 1s-600s
password_encryption = scram-sha-256  # md5 or scram-sha-256
#db_user_namespace = off

# GSSAPI using Kerberos
#krb_server_keyfile = 'FILE:${sysconfdir}/krb5.keytab'
#krb_caseins_users = off

# - SSL -

#ssl = off
#ssl_ca_file = ''
#ssl_cert_file = 'server.crt'
#ssl_crl_file = ''
#ssl_key_file = 'server.key'
#ssl_ciphers = 'HIGH:MEDIUM:+3DES:!aNULL' # allowed SSL ciphers
#ssl_prefer_server_ciphers = on
#ssl_ecdh_curve = 'prime256v1'
#ssl_min_protocol_version = 'TLSv1.2'
#ssl_max_protocol_version = ''
#ssl_dh_params_file = ''
#ssl_passphrase_command = ''
#ssl_passphrase_command_supports_reload = off
```

>Note: All you are doing is uncomment `password_encryption` and setting it to `scram-256`.

As root, edit `/var/lib/pgsql/data/pg_hba.conf` and change `ident` to `scram-256` for the lines below.

Before:

```bash
# IPv4 local connections:
host    all             all             127.0.0.1/32            ident
# IPv6 local connections:
host    all             all             ::1/128                 ident
```

After:

```bash
# IPv4 local connections:
host    all             all             127.0.0.1/32            scram-256
# IPv6 local connections:
host    all             all             ::1/128                 scram-256
```

#### Start PostgreSQL

Start the service and enable it to run at system startup:

```bash
sudo systemctl enable --now postgresql
```

#### Create a Database

At a minimum, we need to create a database for Nautobot and assign it a username and password for authentication. This
is done with the following commands.

!!! danger
    **Do not use the password from the example.** Choose a strong, random password to ensure secure database
    authentication for your Nautobot installation.

```bash
sudo -u postgres psql
```

```bash
postgres=# CREATE DATABASE nautobot;
CREATE DATABASE
postgres=# CREATE USER nautobot WITH PASSWORD 'insecure_password';
CREATE ROLE
postgres=# GRANT ALL PRIVILEGES ON DATABASE nautobot TO nautobot;
GRANT
postgres=# \q
```

>Note: This may seem obvious, but you do not need to follow these directions verbatim. You can change the name of the role and the database to suit your needs, but you must remember to insert those variables into the later `nautobot_config.py`.

#### Verify PostgreSQL Service Availability

You can verify that authentication works issuing the following command and providing the configured password. (Replace `localhost` with your database server if using a remote database.)

If successful, you will enter a `nautobot` prompt. Type `\conninfo` to confirm your connection, or type `\q` to exit.

```bash
$ psql --username nautobot --password --host localhost nautobot
Password for user nautobot:

nautobot=> \conninfo
You are connected to database "nautobot" as user "nautobot" on host "localhost" (address "127.0.0.1") at port "5432".
nautobot=> \q
```

## Setup Redis

```bash
sudo systemctl enable --now redis
```

```bash
redis-cli ping
```

>Note: You should receive a PONG.

### Install and Configure Nautobot

### Configure Nautobot Account and Environment

Create a  user account named nautobot. This user will own all of the Nautobot files, and the Nautobot web services will be configured to run under this account.
The following command also creates the /opt/nautobot directory and sets it as the home directory for the user.

```bash
sudo useradd --shell /bin/bash --create-home --home-dir /opt/nautobot nautobot
```

Create the venv.

```bash
sudo -u nautobot python3 -m venv /opt/nautobot
```

```bash
echo "export NAUTOBOT_ROOT=/opt/nautobot" | sudo tee -a ~nautobot/.bashrc
```

 From here on out these, you must perform actions as the nautobot user because the nautobot user is directly tied to the venv.

```bash
sudo -iu nautobot
```

>Note: ``sudo -iu`` automatically places you in the home directory of the user.

### Install Nautobot

```bash
pip3 install --upgrade pip wheel
```

```bash
pip3 install nautobot
```

Confirm Nautobot Installation and Version
>Note: You should now have a fancy nautobot-server command in your environment. This will be your gateway to all things Nautobot! Run it to confirm the installed version of nautobot:

```python
nautobot-server --version
```

Step 5: Initialize your Configuration

Initialize a new configuration by running nautobot-server init.

However, because we've set the NAUTOBOT_ROOT, this command will automatically create a new nautobot_config.py at the default location based on this at $NAUTOBOT_ROOT/nautobot_config.py:

```python
nautobot-server init
```

```bash
Configuration file created at '/opt/nautobot/nautobot_config.py'
```

Required Settings

Your nautobot_config.py provides sane defaults for all of the configuration settings. You will inevitably need to update the settings for your environment, most notably the DATABASES setting. If you do not wish to modify the config, by default, many of these configuration settings can also be specified by environment variables. Please see Required Settings for further details.

Edit $NAUTOBOT_ROOT/nautobot_config.py, and head over to the documentation on Required Settings to tweak your required settings. At a minimum, you'll need to update the following settings:

- ALLOWED_HOSTS: You must set this value. This can be set to ["*"] for a quick start, but this value is not suitable for production deployment.
    DATABASES: Database connection parameters. If you installed your database server on the same system as Nautobot, you'll need to update the USER and PASSWORD fields here. If you are using MySQL, you'll also need to update the ENGINE field, changing the default database driver suffix from django.db.backends.postgresql to django.db.backends.mysql.
    Redis settings: Redis configuration requires multiple settings including CACHEOPS_REDIS and RQ_QUEUES, if different from the defaults. If you installed Redis on the same system as Nautobot, you do not need to change these settings.

You can also create a template for you organizations Nautobot and that way you can just copy the file over to the server now and in the future.

Install Local Requirements:

```bash
pip3 install -r $NAUTOBOT_ROOT/local_requirements.txt
```

```bash
setfacl -m u:nautobot:rwx /opt/nautobot/local_requirements.txt
```

To add packages to you local_requirements.txt so that it can be installed and kept up to date:

```bash
echo <package> >> $NAUTOBOT_ROOT/local_requirements.txt
```

```bash
nautobot-server migrate
```

```bash
nautobot-server createsuperuser
```

```bash
nautobot-server collectstatic
```

Now you can verify functionality by starting it up in a development mode. This is not for production purposes. It is just to make sure that all of your changes are accepted.

```bash
nautobot-server check
```

```bash
nautobot-server runserver 0.0.0.0:8080 --insecure
```

You can log in and verify your account, then exit the web page and move on to the next steps.

## Deploying Nautobot Web Service and Workers

>As the nautobot server perform the following commands

```bash
cat > $NAUTOBOT_ROOT/uwsgi.ini <<EOF
[uwsgi]
; The IP address (typically localhost) and port that the WSGI process should listen on
socket = 127.0.0.1:8001

; Fail to start if any parameter in the configuration file isn’t explicitly understood by uWSGI
strict = true

; Enable master process to gracefully re-spawn and pre-fork workers
master = true

; Allow Python app-generated threads to run
enable-threads = true

;Try to remove all of the generated file/sockets during shutdown
vacuum = true

; Do not use multiple interpreters, allowing only Nautobot to run
single-interpreter = true

; Shutdown when receiving SIGTERM (default is respawn)
die-on-term = true

; Prevents uWSGI from starting if it is unable load Nautobot (usually due to errors)
need-app = true

; By default, uWSGI has rather verbose logging that can be noisy
disable-logging = true

; Assert that critical 4xx and 5xx errors are still logged
log-4xx = true
log-5xx = true

; Enable HTTP 1.1 keepalive support
http-keepalive = 1

;
; Advanced settings (disabled by default)
; Customize these for your environment if and only if you need them.
; Ref: https://uwsgi-docs.readthedocs.io/en/latest/Options.html
;

; Number of uWSGI workers to spawn. This should typically be 2n+1, where n is the number of CPU cores present.
; processes = 5

; If using subdirectory hosting e.g. example.com/nautobot, you must uncomment this line. Otherwise you'll get double paths e.g. example.com/nautobot/nautobot/.
; Ref: https://uwsgi-docs.readthedocs.io/en/latest/Changelog-2.0.11.html#fixpathinfo-routing-action
; route-run = fixpathinfo:

; If hosted behind a load balancer uncomment these lines, the harakiri timeout should be greater than your load balancer timeout.
; Ref: https://uwsgi-docs.readthedocs.io/en/latest/HTTP.html?highlight=keepalive#http-keep-alive
; harakiri = 65
; add-header = Connection: Keep-Alive
; http-keepalive = 1
EOF
```

### Nautobot Service

>Perform the Following as ``root``

```bash
cat > /etc/systemd/system/nautobot-worker.service <<EOF
[Unit]
Description=Nautobot Celery Worker
Documentation=https://nautobot.readthedocs.io/en/stable/
After=network-online.target
Wants=network-online.target

[Service]
Type=exec
Environment="NAUTOBOT_ROOT=/opt/nautobot"

User=nautobot
Group=nautobot
PIDFile=/var/tmp/nautobot-worker.pid
WorkingDirectory=/opt/nautobot

ExecStart=/opt/nautobot/bin/nautobot-server celery worker --loglevel INFO --pidfile /var/tmp/nautobot-worker.pid

Restart=always
RestartSec=30
PrivateTmp=true

[Install]
WantedBy=multi-user.target
EOF
```

### Nautobot Worker Service

```bash
cat > /etc/systemd/system/nautobot.service <<EOF
[Unit]
Description=Nautobot WSGI Service
Documentation=https://nautobot.readthedocs.io/en/stable/
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
Environment="NAUTOBOT_ROOT=/opt/nautobot"

User=nautobot
Group=nautobot
PIDFile=/var/tmp/nautobot.pid
WorkingDirectory=/opt/nautobot

ExecStart=/opt/nautobot/bin/nautobot-server start --pidfile /var/tmp/nautobot.pid --ini /opt/nautobot/uwsgi.ini
ExecStop=/opt/nautobot/bin/nautobot-server start --stop /var/tmp/nautobot.pid
ExecReload=/opt/nautobot/bin/nautobot-server start --reload /var/tmp/nautobot.pid

Restart=on-failure
RestartSec=30
PrivateTmp=true

[Install]
WantedBy=multi-user.target
EOF
```

#### Configure Systemd for new Services

Because we just added new service files, you'll need to reload the systemd daemon:

```bash
sudo systemctl daemon-reload
```

```bash
sudo systemctl enable --now nautobot nautobot-worker
```

Verify Services

```bash
systemctl status nautobot
```

```bash
systemctl status nautobot-worker
```

### Configure HTTP Server

Note: This section may differ significantly depending on your organization. With that being said, I am only going to cover self-signed certificates

```bash
sudo openssl req -x509 -nodes -days 365 -newkey rsa:4096 \
  -keyout /etc/pki/tls/private/nautobot.key \
  -out /etc/pki/tls/certs/nautobot.crt
```

```bash
cat > /etc/nginx/conf.d/nautobot.conf <<EOF
server {
    listen 443 ssl http2 default_server;
    listen [::]:443 ssl http2 default_server;

    server_name _;

    ssl_certificate /etc/pki/tls/certs/nautobot.crt;
    ssl_certificate_key /etc/pki/tls/private/nautobot.key;

    client_max_body_size 25m;

    location /static/ {
        alias /opt/nautobot/static/;
    }

    # For subdirectory hosting, you'll want to toggle this (e.g. `/nautobot/`).
    # Don't forget to set `FORCE_SCRIPT_NAME` in your `nautobot_config.py` to match.
    # location /nautobot/ {
    location / {
        include uwsgi_params;
        uwsgi_pass  127.0.0.1:8001;
        uwsgi_param Host $host;
        uwsgi_param X-Real-IP $remote_addr;
        uwsgi_param X-Forwarded-For $proxy_add_x_forwarded_for;
        uwsgi_param X-Forwarded-Proto $http_x_forwarded_proto;

        # If you want subdirectory hosting, uncomment this. The path must match
        # the path of this location block (e.g. `/nautobot`). For NGINX the path
        # MUST NOT end with a trailing "/".
        # uwsgi_param SCRIPT_NAME /nautobot;
    }

}

server {
    # Redirect HTTP traffic to HTTPS
    listen 80 default_server;
    listen [::]:80 default_server;
    server_name _;
    return 301 https://$host$request_uri;
}
EOF
```

```bash
sudo sed -i 's@ default_server@@' /etc/nginx/nginx.conf
```

```bash
systemctl enable --now nginx
```

```bash
systemctl status nginx
```

As the ``nautobot`` user perform the following

```bash
chmod 755 $NAUTOBOT_ROOT
```

You can now access the Nautobot login page via the IPv4 address you set for the operating system.

## Applying DISA Security Technical Implementation Guide to Nautobot

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

## Upgrading a Disconnected Nautobot Server

The process of upgrading Nautobot is relatively simple unless you are operating your server in an air-gapped environment where certain luxuries such as a Pulp3 Content Server are not present. I will be covering both the Normal upgrade process as well as the confusing process. That way, you can compare the two different methods.

### Normal Nautobot Upgrade

source: [Upgrading to a New Nautobot Release](https://nautobot.readthedocs.io/en/stable/installation/upgrading/)

Review the Release Notes

Prior to upgrading your Nautobot instance, be sure to carefully review all [release notes](../../release-notes/) that
have been published since your current version was released. Although the upgrade process typically does not involve
additional work, certain releases may introduce breaking or backward-incompatible changes. These are called out in the
release notes under the release in which the change went into effect.

### Update Prerequisites to Required Versions

Nautobot v1.0.0 and later requires the following:

| Dependency | Minimum Version |
| ---------- | --------------- |
| Python     | 3.6             |
| PostgreSQL | 9.6             |
| Redis      | 4.0             |

### Install the Latest Release

As with the initial installation, you can upgrade Nautobot by installing the Python package directly from the Python Package Index (PyPI).

!!! warning
    Unless explicitly stated, all steps requiring the use of `pip3` or `nautobot-server` in this document should be performed as the `nautobot` user!

Upgrade Nautobot using `pip3`:

```bash
pip3 install --upgrade nautobot
```

### Upgrade your Optional Dependencies

If you do not have any optional dependencies, you may skip this step.

Once the new code is in place, verify that any optional Python packages required by your deployment (e.g. `napalm` or
`django-auth-ldap`) are listed in `local_requirements.txt`.

Then, upgrade your dependencies using `pip3`:

```bash
pip3 install --upgrade -r $NAUTOBOT_ROOT/local_requirements.txt
```

### Run the Post Upgrade Operations

Finally, run Nautobot's `post_upgrade` management command:

```bash
nautobot-server post_upgrade
```

This command performs the following actions:

- Applies any database migrations that were included in the release
- Generates any missing cable paths among all cable termination objects in the database
- Collects all static files to be served by the HTTP service
- Deletes stale content types from the database
- Deletes all expired user sessions from the database
- Clears all cached data to prevent conflicts with the new release

### Restart the Nautobot Services

Finally, with root permissions, restart the web and background services:

```bash
sudo systemctl restart nautobot nautobot-worker
```

## Disconnected Nautobot Upgrade

These steps are based on the assumption that you are one of those poor engineers still stuck in the Stone Age, assuming you are in a completely disconnected environment and will have to transfer the python packages over to the server either on a disk or a disk an external hard drive.

Reference: <https://pip.pypa.io/en/stable/cli/pip_download/#usage>

We will be using pip download to download the python packages for nautobot and the required dependency upgrades needed to perform a successful upgrade. In addition, you may need to do this for whatever plugins you utilize in your environment.

## Closing Comments

There are still many changes coming to this guide and a lot of things to be tested. I decided to redo my documentation because it was getting difficult for even myself to read and understand. Please feel free to submit an issue if you see something wrong or something that could be better.

### Resources

- [DISA STIG Document Library](https://public.cyber.mil/stigs/downloads/)
- [Docisfy](https://docsify.js.org)
