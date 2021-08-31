FROM registry.redhat.io/ubi8/ubi
<<<<<<< HEAD
=======

>>>>>>> 4ff8e8c6b3b04149ccbf293eee7d05c8cf80a5a2
USER root
RUN yum install wget unzip -y
# COPY /repos/yum.repos.d/ /etc/yum.repos.d/
RUN yum install rsync openssh openssh-clients openssl openssl-devel iproute iputils nano python3 python3-devel libffi-devel gcc git -y
# Add User
RUN useradd xadmin
RUN echo -e "mypass\nmypass" | passwd xadmin
# Prep Nautobot
RUN useradd --system --shell /bin/bash --create-home --home-dir /opt/nautobot nautobot
RUN python3 -m venv /opt/nautobot
RUN echo "export NAUTOBOT_ROOT=/opt/nautobot" | tee -a ~nautobot/.bashrc
USER nautobot
RUN echo $NAUTOBOT_ROOT
RUN echo $PATH
RUN which pip3
USER root
RUN pip3 install --upgrade pip wheel
RUN pip3 install nautobot
# Fix issue related to urllib3 package, will receive Warnings when starting Nautobot
RUN pip3 uninstall urllib3 -y
RUN pip3 install urllib3
# Replace utils.py with FIPS compliant code
COPY /nautobot/backends_utils.py /usr/local/lib/python3.6/site-packages/django/db/backends/utils.py
COPY /nautobot/cacheops_utils.py /usr/local/lib/python3.6/site-packages/cacheops/utils.py
# Copy over Nautobot Config, Notes and Scripts
USER nautobot
RUN nautobot-server init
COPY /nautobot/nautobot_config.py /opt/nautobot/nautobot_config.py
COPY /nautobot/prep_nautobot.sh /opt/nautobot/prep_nautobot.sh
# Start Services
CMD [ "/sbin/init" ]
# CMD [ "/bin/bash" ]