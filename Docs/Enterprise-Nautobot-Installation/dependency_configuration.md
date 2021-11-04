# Installing and Configuring Nautobot Dependencies

The following minimum versions are required for Nautobot to operate and the versions I have tested in production environments. I will not be using MySQL, so I will not be trying or going over that.

| Dependency | Role         | Minimum Version | Production Tested |
| ---------- | ------------ | --------------- | ----------------- |
| Python     | Application  | 3.6             | 3.9.7             |
| PostgreSQL | Database     | 9.6             | 14.1              |
| Redis      | Cache, Queue | 4.0             | 6.1               |

## Configure PostgreSQL Database

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