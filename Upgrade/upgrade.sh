#!/bin/bash
#------------------------------------------------------------ #
# By @beholdenkey
# Compatible Operating systems: RHEL 8
# Script to Upgrade Nautobot -  RHEL 8
# Run as Nautobot User
#------------------------------------------------------------- #

echo "Changing to Nautobot User"
sudo -iu nautobot

echo 'Upgrading Nautobot'
pip3 install --upgrade nautobot

echo 'Upgrading Nautobot Local_Requirements'
pip3 install --upgrade -r $NAUTOBOT_ROOT/local_requirements.txt

echo 'Running Post Upgrade'
nautobot-server post_upgrade

echo 'Restarting Nautobot & Nautobot Worker'
sudo systemctl restart nautobot nautobot-worker