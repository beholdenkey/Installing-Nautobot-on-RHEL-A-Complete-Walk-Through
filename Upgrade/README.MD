# Upgrading Nautobot

Upgrading the Nautobot application is a relatively painless process. However if you have applied a STIG to the Operating System there are some changes you will have to take into consideration when you are going through the upgrade process.

When the STIG is applied it will remove the base OpenSSL package and install the OpenSSL FIPS compliant package. This will cause some issues because Nautobot uses the MD5 hashing algorithm and per the Federal Information Processing Standard 140-2 (FIPS 140-2)