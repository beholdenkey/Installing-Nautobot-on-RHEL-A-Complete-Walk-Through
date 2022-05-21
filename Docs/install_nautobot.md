# Installing Nautobot

## Installing Configure Nautobot Account and Environment

Create a  user account named nautobot. This user will own all of the Nautobot files, and the Nautobot web services will be configured to run under this account.
The following command also creates the /opt/nautobot directory and sets it as the home directory for the user.

```bash
sudo useradd --shell /bin/bash --create-home --home-dir /opt/nautobot nautobot
```

Create the venv.

```bash
sudo -u nautobot python3 -m venv /opt/nautobot
```

```bash
"export NAUTOBOT_ROOT=/opt/nautobot" | sudo tee -a ~nautobot/.bashrc
```

 From here on out these, you must perform actions as the nautobot user because the nautobot user is directly tied to the venv.

```bash
sudo -iu
```

>Note: ``sudo -iu`` automatically places you in the home directory of the user.

### Install Nautobot

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

Initialize a new configuration by running nautobot-server init.

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

```bash
nautobot-server migrate
```

```bash
nautobot-server createsuperuser
```

```bash
nautobot-server collectstatic
```

Now you can verify functionality by starting it up in a development mode. This is not for production purposes. It is just to make sure that all of your changes are accepted.

```bash
nautobot-server check
```

```bash
nautobot-server runserver 0.0.0.0:8080 --insecure
```

You can log in and verify your account, then exit the web page and move on to the next steps.

## Deploying Nautobot Web Service and Workers

>As the nautobot server perform the following commands

```bash
cat > $NAUTOBOT_ROOT/uwsgi.ini <<EOF
[uwsgi]
; The IP address (typically localhost) and port that the WSGI process should listen on
socket = 127.0.0.1:8001

; Fail to start if any parameter in the configuration file isn’t explicitly understood by uWSGI
strict = true

; Enable master process to gracefully re-spawn and pre-fork workers
master = true

; Allow Python app-generated threads to run
enable-threads = true

;Try to remove all of the generated file/sockets during shutdown
vacuum = true

; Do not use multiple interpreters, allowing only Nautobot to run
single-interpreter = true

; Shutdown when receiving SIGTERM (default is respawn)
die-on-term = true

; Prevents uWSGI from starting if it is unable load Nautobot (usually due to errors)
need-app = true

; By default, uWSGI has rather verbose logging that can be noisy
disable-logging = true

; Assert that critical 4xx and 5xx errors are still logged
log-4xx = true
log-5xx = true

; Enable HTTP 1.1 keepalive support
http-keepalive = 1

;
; Advanced settings (disabled by default)
; Customize these for your environment if and only if you need them.
; Ref: https://uwsgi-docs.readthedocs.io/en/latest/Options.html
;

; Number of uWSGI workers to spawn. This should typically be 2n+1, where n is the number of CPU cores present.
; processes = 5

; If using subdirectory hosting e.g. example.com/nautobot, you must uncomment this line. Otherwise you'll get double paths e.g. example.com/nautobot/nautobot/.
; Ref: https://uwsgi-docs.readthedocs.io/en/latest/Changelog-2.0.11.html#fixpathinfo-routing-action
; route-run = fixpathinfo:

; If hosted behind a load balancer uncomment these lines, the harakiri timeout should be greater than your load balancer timeout.
; Ref: https://uwsgi-docs.readthedocs.io/en/latest/HTTP.html?highlight=keepalive#http-keep-alive
; harakiri = 65
; add-header = Connection: Keep-Alive
; http-keepalive = 1
EOF
```

### Nautobot Service

>Perform the Following as ``root``

```bash
cat > /etc/systemd/system/nautobot-worker.service <<EOF
[Unit]
Description=Nautobot Celery Worker
Documentation=https://nautobot.readthedocs.io/en/stable/
After=network-online.target
Wants=network-online.target

[Service]
Type=exec
Environment="NAUTOBOT_ROOT=/opt/nautobot"

User=nautobot
Group=nautobot
PIDFile=/var/tmp/nautobot-worker.pid
WorkingDirectory=/opt/nautobot

ExecStart=/opt/nautobot/bin/nautobot-server celery worker --loglevel INFO --pidfile /var/tmp/nautobot-worker.pid

Restart=always
RestartSec=30
PrivateTmp=true

[Install]
WantedBy=multi-user.target
EOF
```

### Nautobot Worker Service

```bash
cat > /etc/systemd/system/nautobot.service <<EOF
[Unit]
Description=Nautobot WSGI Service
Documentation=https://nautobot.readthedocs.io/en/stable/
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
Environment="NAUTOBOT_ROOT=/opt/nautobot"

User=nautobot
Group=nautobot
PIDFile=/var/tmp/nautobot.pid
WorkingDirectory=/opt/nautobot

ExecStart=/opt/nautobot/bin/nautobot-server start --pidfile /var/tmp/nautobot.pid --ini /opt/nautobot/uwsgi.ini
ExecStop=/opt/nautobot/bin/nautobot-server start --stop /var/tmp/nautobot.pid
ExecReload=/opt/nautobot/bin/nautobot-server start --reload /var/tmp/nautobot.pid

Restart=on-failure
RestartSec=30
PrivateTmp=true

[Install]
WantedBy=multi-user.target
EOF
```

#### Configure Systemd for new Services

Because we just added new service files, you'll need to reload the systemd daemon:

```bash
sudo systemctl daemon-reload
```

```bash
sudo systemctl enable --now nautobot nautobot-worker
```

Verify Services

```bash
systemctl status nautobot
```

```bash
systemctl status nautobot-worker
```


### Configure HTTP Server

Note: This section may differ significantly depending on your organization. With that being said, I am only going to cover self-signed certificates

```bash
sudo openssl req -x509 -nodes -days 365 -newkey rsa:4096 \
  -keyout /etc/pki/tls/private/nautobot.key \
  -out /etc/pki/tls/certs/nautobot.crt
```

```bash
cat > /etc/nginx/conf.d/nautobot.conf <<EOF
server {
    listen 443 ssl http2 default_server;
    listen [::]:443 ssl http2 default_server;

    server_name _;

    ssl_certificate /etc/ssl/certs/nautobot.crt;
    ssl_certificate_key /etc/ssl/private/nautobot.key;

    client_max_body_size 25m;

    location /static/ {
        alias /opt/nautobot/static/;
    }

    # For subdirectory hosting, you'll want to toggle this (e.g. `/nautobot/`).
    # Don't forget to set `FORCE_SCRIPT_NAME` in your `nautobot_config.py` to match.
    # location /nautobot/ {
    location / {
        include uwsgi_params;
        uwsgi_pass  127.0.0.1:8001;
        uwsgi_param Host $host;
        uwsgi_param X-Real-IP $remote_addr;
        uwsgi_param X-Forwarded-For $proxy_add_x_forwarded_for;
        uwsgi_param X-Forwarded-Proto $http_x_forwarded_proto;

        # If you want subdirectory hosting, uncomment this. The path must match
        # the path of this location block (e.g. `/nautobot`). For NGINX the path
        # MUST NOT end with a trailing "/".
        # uwsgi_param SCRIPT_NAME /nautobot;
    }

}

server {
    # Redirect HTTP traffic to HTTPS
    listen 80 default_server;
    listen [::]:80 default_server;
    server_name _;
    return 301 https://$host$request_uri;
}
EOF
```

```bash
sudo sed -i 's@ default_server@@' /etc/nginx/nginx.conf
```

```bash
systemctl enable --now nginx
```

```bash
systemctl status nginx
```

As the ``nautobot`` user perform the following

```bash
chmod 755 $NAUTOBOT_ROOT
```

You can now access the Nautobot login page via the IPv4 address you set for the operating system.
