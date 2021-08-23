# Installing Nautobot on Red Hat Enterprise Linux - A Complete Walk Through

This is meant to assist users in installing Nautobot on Red Hat Enterprise Linux. I will go through the process of installation, hardening, and STIG implementation. This will be all done on a Virtual Machine. In addition, I will be using the ansible-playbook for the RHEL 8 STIG implementation. Please refer to the resources directory for the links to these repositories.

>Note: As of right now, this guide will not go through installing Nautobot in a disconnected environment.

Also, if you are not familiar with the dependencies of Nautobot, I highly recommend that you do some reading because nautobot consists of a rather diverse Application Stack.

Future Plans:

- Create Playbook with vars that support installation an configuration of either server installation and or container installation.

## Pre-requisites

Minimum VM Resource Requirements:
>Note: These are the minimum requirements these are not the recommended requirements for a production environment.

- vCores - 4
- Memory - 8 GiB
- Storage - 125 GiB

Nautobot has the following minimum version requirements for its dependencies:

- Python: 3.6
- PostgreSQL: 9.6
- Redis: 4.0

Dependency versions I have successfully used on production Nautobot Server:

- Python: 3.9.6
- PostgreSQL: 13.3-4
- Redis 5.2

>Note if you are not using the latest version of python and would like to install the latest version from source please go to the following link <https://github.com/beholdenkey/Installing-Nautobot-on-RHEL-A-Complete-Walk-Through/blob/main/Resources/python_install.sh> However you can also install latest python available for that OS through the following commands

```bash
dnf -y install \
    python39 \
    python39-devel \
    python39-pip
```

>Note: Keep in mind that we will be applying the RHEL 8 STIG and this will require additional resources for the increased storage requirements.

Step 1:

```bash
git clone https://github.com/beholdenkey/Installing-Nautobot-on-RHEL-A-Complete-Walk-Through.git
```

```bash
chmod +x setup.sh
```

```bash
./setup.sh
```

>Note: It is crucial that you review the setup.sh file before execution this is not one of those scripts that will do everything for you.

Step 2:

Create the database
>Note: This process will not go into setting up anything more than the bare minimum required database to support the Nautobot application. In the future I wil add documentation and instructions supporting my stream replication as well as load balancing support.

```bash
sudo -u postgres psql
```

>Note: These passwords are not secure and it is highly recommended that you set the password for the postgres role because if the password is not set there is essentially nothing stop someone from making changes if they are able to access the server.

```SQL
postgres=# CREATE DATABASE nautobot;
```

```SQL
postgres=# CREATE USER nautobot WITH PASSWORD 'insecure_password';
```

```SQL
postgres=# GRANT ALL PRIVILEGES ON DATABASE nautobot TO nautobot;
```

``SQL
postgres=# \q
```

Verify the Service Status

You can verify that authentication works issuing the following command and providing the configured password. (Replace localhost with your database server if using a remote database.)

If successful, you will enter a nautobot prompt. Type \conninfo to confirm your connection, or type \q to exit.

>Now that you have exited you will need to go back in as the Nautobot Role and Connect to the Nautobot Database both of which you just created previously.

```SQL
psql --username nautobot --password --host localhost nautobot
```

```SQL
nautobot=> \conninfo
You are connected to database "nautobot" as user "nautobot" on host "localhost" (address "127.0.0.1") at port "5432".
```

By default these setting are sufficient because this database all need to be accessed locally by the Nautobot application.
