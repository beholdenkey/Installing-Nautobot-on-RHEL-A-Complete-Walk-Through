# LDAP Authentication

>Note: This is a copy and paste from [Nautobot Read The Docs](https://nautobot.readthedocs.io/en/stable/configuration/authentication/ldap/)
Install System Packages

```bash
dnf -y install openldap-devel
```

Install django-auth-ldap

>Note: The remaining steps need to be run as the nautobot user
>Hint: sudo -iu nautobot

```bash
pip3 install django-auth-ldap
```

Once installed, add the package to local_requirements.txt to ensure it is re-installed during future rebuilds of the virtual environment:

```bash
echo django-auth-ldap >> /opt/nautobot/local_requirements.txt
```

## Configuration

Enable the LDAP authentication backend by adding the following to your nautobot_config.py:

>Note:It is critical that you include the ObjectPermissionsBackend provided by Nautobot after the LDAPBackend so that object-level permissions features can work properly.

```python
AUTHENTICATION_BACKENDS = [
    'django_auth_ldap.backend.LDAPBackend',
    'nautobot.core.authentication.ObjectPermissionBackend',
]
```

General Server Configuration

Define all of the parameters required below in your nautobot_config.py. Complete documentation of all django-auth-ldap configuration options is included in the project's official documentation.

```python
import ldap

# Server URI
AUTH_LDAP_SERVER_URI = "ldaps://ad.example.com"

# The following may be needed if you are binding to Active Directory.
AUTH_LDAP_CONNECTION_OPTIONS = {
    ldap.OPT_REFERRALS: 0
}

# Set the DN and password for the Nautobot service account.
AUTH_LDAP_BIND_DN = "CN=NAUTOBOTSA, OU=Service Accounts,DC=example,DC=com"
AUTH_LDAP_BIND_PASSWORD = "demo"

# Include this `ldap.set_option` call if you want to ignore certificate errors. This might be needed to accept a self-signed cert.
ldap.set_option(ldap.OPT_X_TLS_REQUIRE_CERT, ldap.OPT_X_TLS_NEVER)
```

TLS Options

STARTTLS can be configured by setting AUTH_LDAP_START_TLS = True and using the ldap:// URI scheme.

Apply TLS settings to the internal SSL context on nautobot by configuring ldap.OPT_X_TLS_NEWCTX with value 0.

```python
AUTH_LDAP_SERVER_URI = "ldap://ad.example.com"
AUTH_LDAP_START_TLS = True
# Set the path to the trusted CA certificates and create a new internal SSL context.
AUTH_LDAP_CONNECTION_OPTIONS = {
    ldap.OPT_X_TLS_CACERTFILE: "/path/to/ca.pem",
    ldap.OPT_X_TLS_NEWCTX: 0
}
```

User Authentication

```python
from django_auth_ldap.config import LDAPSearch
# This search matches users with the sAMAccountName equal to the provided username. This is required if the user's
# username is not in their DN (Active Directory).
AUTH_LDAP_USER_SEARCH = LDAPSearch("ou=Users,dc=example,dc=com",
                                    ldap.SCOPE_SUBTREE,
                                    "(sAMAccountName=%(user)s)")

# If a user's DN is producible from their username, we don't need to search.
AUTH_LDAP_USER_DN_TEMPLATE = "uid=%(user)s,ou=users,dc=example,dc=com"

# You can map user attributes to Django attributes as so.
AUTH_LDAP_USER_ATTR_MAP = {
    "first_name": "givenName",
    "last_name": "sn",
    "email": "mail"
}
```

User Groups for Permissions

>Note:When using Microsoft Active Directory, support for nested groups can be activated by using NestedGroupOfNamesType() instead of GroupOfNamesType() for AUTH_LDAP_GROUP_TYPE. You will also need to modify the import line to use NestedGroupOfNamesType instead of GroupOfNamesType .

```python
from django_auth_ldap.config import LDAPSearch, GroupOfNamesType

# This search ought to return all groups to which the user belongs. django_auth_ldap uses this to determine group
# hierarchy.
AUTH_LDAP_GROUP_SEARCH = LDAPSearch("dc=example,dc=com", ldap.SCOPE_SUBTREE,
                                    "(objectClass=group)")
AUTH_LDAP_GROUP_TYPE = GroupOfNamesType()

# Define a group required to login.
AUTH_LDAP_REQUIRE_GROUP = "CN=NAUTOBOT_USERS,DC=example,DC=com"

# Define special user types using groups. Exercise great caution when assigning superuser status.
AUTH_LDAP_USER_FLAGS_BY_GROUP = {
    "is_active": "cn=active,ou=groups,dc=example,dc=com",
    "is_staff": "cn=staff,ou=groups,dc=example,dc=com",
    "is_superuser": "cn=superuser,ou=groups,dc=example,dc=com"
}

# For more granular permissions, we can map LDAP groups to Django groups.
AUTH_LDAP_FIND_GROUP_PERMS = True

# Cache groups for one hour to reduce LDAP traffic
AUTH_LDAP_CACHE_TIMEOUT = 3600
```

- is_active - All users must be mapped to at least this group to enable authentication. Without this, users cannot log in.
- is_staff - Users mapped to this group are enabled for access to the administration tools; this is the equivalent of checking the "staff status" box on a manually created user. This doesn't grant any specific permissions.
- is_superuser - Users mapped to this group will be granted superuser status. Superusers are implicitly granted all permissions.

>Note: Authentication will fail if the groups (the distinguished names) do not exist in the LDAP directory.

Troubleshooting LDAP

systemctl restart nautobot restarts the Nautobot service, and initiates any changes made to nautobot_config.py. If there are syntax errors present, the Nautobot process will not spawn an instance, and errors should be logged to /var/log/messages.

For troubleshooting LDAP user/group queries, add or merge the following logging configuration to nautobot_config.py:

```python
LOGGING = {
    'version': 1,
    'disable_existing_loggers': False,
    'handlers': {
        'nautobot_auth_log': {
            'level': 'DEBUG',
            'class': 'logging.handlers.RotatingFileHandler',
            'filename': '/opt/nautobot/logs/django-ldap-debug.log',
            'maxBytes': 1024 * 500,
            'backupCount': 5,
        },
    },
    'loggers': {
        'django_auth_ldap': {
            'handlers': ['nautobot_auth_log'],
            'level': 'DEBUG',
        },
    },
}
```

Ensure the file and path specified in logfile exist and are writable and executable by the application service account. Restart the nautobot service and attempt to log into the site to trigger log entries to this file.
