# Resources

Nautobot Documentation - <https://nautobot.readthedocs.io/en/stable/>

Nautobot Github Repository - <https://github.com/nautobot/nautobot>

Nautobot PyPi - <https://pypi.org/project/nautobot/>

Installing Nautobot - A Complete Walk-through - May 6 2021 - <https://blog.networktocode.com/post/installing-nautobot/>
>Note: This walk-through is for Ubuntu, there are also some rather big changes that have been made to the overall code source since this Walk-through was made.

Red Hat PostgreSQL Installation - <https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/8/html/deploying_different_types_of_servers/using-databases#introduction-to-postgresql_using>

Redis - <https://redis.io/>

uWSGI Documentation - <https://uwsgi-docs.readthedocs.io/en/latest/>

Celery Documentation - <https://docs.celeryproject.org/en/stable/>

NGINX Reverse Proxy - <https://docs.nginx.com/nginx/admin-guide/web-server/reverse-proxy/>

OpenSSL - <https://www.openssl.org/>

Red Hat Official RHEL8_STIG: <https://galaxy.ansible.com/redhatofficial/rhel8_stig>

Red Hat Gov Playbook: <https://github.com/RedHatGov/rhel8-stig-latest>

Plugins: # Enable installed plugins. Add the name of each plugin to the list.
PLUGINS = ["nautobot_data_validation_engine", "nautobot_netbox_importer", "nautobot_plugin_nornir", "nautobot_golden_config"]

Plugins configuration settings. These settings are used by various plugins that the user may have installed.
Each key in the dictionary is the name of an installed plugin and its value is a dictionary of settings.
PLUGINS_CONFIG = {
    "nautobot_plugin_nornir": {
        "nornir_settings": {
            "credentials": "nautobot_plugin_nornir.plugins.credentials.env_vars.CredentialsEnvVars",
            "runner": {
                "plugin": "threaded",
                "options": {
                    "num_workers": 20,
                },
            },
        },
    },
    "nautobot_golden_config": {
        "per_feature_bar_width": 0.15,
        "per_feature_width": 13,
        "per_feature_height": 4,
        "enable_backup": True,
        "enable_compliance": True,
        "enable_intended": True,
        "enable_sotagg": True,
        "sot_agg_transposer": None,
        "platform_slug_map": None,
    },
}