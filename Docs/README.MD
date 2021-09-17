# Step by Step Walk-Through of Nautobot Installation on RHEL 8

## RHEL 8 Initial Setup

Before we do anything else, we will need to perform the initial configurations, such as selecting the necessary language. The following steps will be changes that may be depending on your organization's policies; however, the partition changes are a hard requirement.

First, we will go to the installation destination and perform the necessary partitions.

Step 1: Go down to "Storage Configuration," and select custom, and then click done.

Step 2: Click the "Click here to create them automatically" If you do click create them automatically, you will need to go back and reduce the partition size of the other partitions to give yourself enough space to create the new ones. (From here, you will add in the additional data and system partitions)

Step 3: Create the following partitions.(For now, I will not have the ratios available)

DATA

- /var/log
- /var/log/audit
- /var/tmp

SYSTEM

- /tmp
- /var

For an example of how this may look when done please see below.
![RHEL 8 Partition STIG Example](https://github.com/beholdenkey/Installing-Nautobot-on-RHEL-A-Complete-Walk-Through/blob/main/Resources/Images/RHEL%208%20Partition%20STIG.PNG)

Step 4: Got to the KDUMP and click disable

Step 5: Configure you Network and Hostname

Step 6: Connect to your Red Hat CDN

Step 7: Make your software selection (I normally select "Minimal Install")

Step 8: Setup your root and User Account

## Nautobot Installation and Configuration

>Note: You do not need to clone my repo to your system; this is convenient and will allow you to copy and move files versus typing them out.

```bash
git clone https://github.com/beholdenkey/Installing-Nautobot-on-RHEL-A-Complete-Walk-Through.git
```

```bash
chmod +x setup.sh
```

```bash
./setup.sh
```

>Note: You must review the setup.sh file before execution; this is not one of those scripts that will do everything for you.

Step 2:

Create the database
>Note: This process will not set up anything more than the bare minimum required database to support the Nautobot application. In the future, I will add documentation and instructions supporting my stream replication and load balancing support.

```bash
sudo -u postgres psql
```

>Note: These passwords are not secure, and it is highly recommended that you set the password for the Postgres role because if the password is not set, there is essentially nothing to stop someone from making changes if they can access the server.

```SQL
postgres=# CREATE DATABASE nautobot;
```

```SQL
postgres=# CREATE USER nautobot WITH PASSWORD 'insecure_password';
```

```SQL
postgres=# GRANT ALL PRIVILEGES ON DATABASE nautobot TO nautobot;
```

```SQL
postgres=# \q
```

Verify the Service Status

You can verify that authentication works by issuing the following command and providing the configured password. (Replace localhost with your database server if using a remote database.)

If successful, you will enter a nautobot prompt. Type \conninfo to confirm your connection, or type \q to exit.

>Note: Now that you have exited, you will need to go back in as the Nautobot Role and Connect to the Nautobot Database, both of which you previously created.

```SQL
psql --username nautobot --password --host localhost nautobot
```

```SQL
nautobot=> \conninfo
You are connected to database "nautobot" as user "nautobot" on host "localhost" (address "127.0.0.1") at port "5432".
```

By default, these settings are sufficient because this database all be accessed locally by the Nautobot application.

Step 3:

```bash
systemctl enable --now redis
```

```bash
redis-cli ping
```

```redis
PONG
```

>Note: This is sufficient when it comes to configuring redis

Step 4: Create the Nautobot System User

Create a system user account named nautobot. This user will own all of the Nautobot files, and the Nautobot web services will be configured to run under this account.

The following command also creates the /opt/nautobot directory and sets it as the home directory for the user.

```bash
sudo useradd --system --shell /bin/bash --create-home --home-dir /opt/nautobot nautobot
```

Step 5: Setup Virtual Environment

A Python virtual environment or virtualenv is like a container for a set of Python packages. A virtualenv allows you to build environments suited to specific projects without interfering with system packages or other projects.

When installed per the documentation, Nautobot uses a virtual environment in production.

In the following steps, we will have you create the virtualenv within the NAUTOBOT_ROOT you chose in the previous step. This is the same we had you set as the home directory as the nautobot user.

>Note: Instead of deliberately requiring you to activate/deactivate the virtualenv, we are emphasizing on relying on the $PATH to access programs installed within it. We find this to be much more intuitive and natural when working with Nautobot in this way.

As root, we're going to create the virtualenv in our NAUTOBOT_ROOT as the nautobot user to populate the /opt/nautobot directory with a self-contained Python environment including a bin directory for scripts and a lib directory for Python libraries.

```bash
sudo -u nautobot python3 -m venv /opt/nautobot
```

Update the Nautobot .bashrc

```bash
echo "export NAUTOBOT_ROOT=/opt/nautobot" | sudo tee -a ~nautobot/.bashrc
```

>Note: It is critical to install Nautobot as the nautobot user so that we don't have to worry about fixing permissions later.

```bash
sudo -iu nautobot
```

>Note: Unless explicitly stated, all remaining steps requiring the use of pip3 or nautobot-server in this document should be performed as the nautobot user!

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

Initialize a new configuration by running nautobot-server init. You may specify an alternate location and detailed instructions for this are covered in the documentation on Nautobot Configuration.

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

To add packages to you local_requirements.txt so that it can be installed and kept up to date:

```bash
echo <package> >> $NAUTOBOT_ROOT/local_requirements.txt
```