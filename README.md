# Installing Nautobot on Red Hat Enterprise Linux - A Complete Walk Through

This is meant to assist users in installing Nautobot on Red Hat Enterprise Linux. I will go through the process of installation, hardening, and STIG implementation. This will be all done on a Virtual Machine. In addition, I will be using the ansible-playbook for the RHEL 8 STIG implementation. Please refer to the resources directory for the links to these repositories.

>Note: As of right now, this guide will not go through installing Nautobot in a disconnected environment.

Also, if you are not familiar with the dependencies of Nautobot, I highly recommend that you do some reading because nautobot consists of a rather diverse Application Stack.

## Pre-requisites

Minimum VM Resource Requirements:
>Note: These are the minimum requirements these are not the recommended requirements for a production environment.

vCores - 4
Memory - 8 GiB
Storage - 125 GiB

>Note: Keep in mind that we will be applying the RHEL 8 STIG and this will require additional resources for the increased storage requirements.
