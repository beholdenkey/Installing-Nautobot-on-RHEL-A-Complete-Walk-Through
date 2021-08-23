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
