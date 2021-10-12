# Upgrading Nautobot

Upgrading the Nautobot application is a relatively painless process. However if you have applied a STIG to the Operating System there are some changes you will have to take into consideration when you are going through the upgrade process.

When the STIG is applied it will remove the base OpenSSL package and install the OpenSSL FIPS compliant package. This will cause some issues because Nautobot uses the MD5 hashing algorithm and per the Federal Information Processing Standard 140-2 (FIPS 140-2)

There are a few possible resolutions to this problem. The initial resolution is to enable FIPS mode before the server is installed and configured. This will ensure that the correct algorithms are used prior to applying a STIG.

You can enable or disable FIPS using the following commands:

```bash
fips-mode-setup --enable
```

```bash
fips-mode-setup --disable
```

>Note: When you enable or disable FIPS you will need to perform a reboot after for it to take effect.
