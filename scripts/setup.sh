#!/bin/sh

set -e

detect_os() {
    if [ -e /etc/os-release ]; then
        . /etc/os-release
        OS=$NAME
        VER=$VERSION_ID
    elif [ -e /etc/redhat-release ]; then
        # Older Red Hat, CentOS, etc.
        OS=$(cat /etc/redhat-release)
    elif [ -e /etc/fedora-release ]; then
        # Fedora
        OS=$(cat /etc/fedora-release)
    else
        unknown_os
    fi
    export OS="$OS"
    export VER="$VER"
}

disable_kdump() {
    if [ -e /etc/sysconfig/kdump ]; then
        sed -i 's/KDUMP_ENABLED=1/KDUMP_ENABLED=0/g' /etc/sysconfig/kdump
    fi
}

update_os() {
    if [ "$OS" = "RedHat" ]; then
        sudo dnf update -y
    elif [ "$OS" = "Fedora" ]; then
        sudo dnf update -y
    else
        echo "Unsupported OS: $OS"
    fi
}

verify_system() {
    if [ -x /bin/systemctl ] || type systemctl >/dev/null 2>&1; then
        HAS_SYSTEMD=true
        return
    fi
    fatal 'Can not find systemd to use as a process supervisor'
}

firewall_setup() {
    if [ "$OS" = "RedHat" ]; then
        sudo systemctl enable firewalld
        sudo systemctl start firewalld
    elif [ "$OS" = "Fedora" ]; then
        sudo systemctl enable firewalld
        sudo systemctl start firewalld
    else
        echo "Unsupported OS: $OS"
    fi
}

firewall_rules() {
    if [ "$OS" = "RedHat" ]; then
        sudo firewall-cmd --permanent --add-port=80/tcp
        sudo firewall-cmd --permanent --add-port=443/tcp
        firewall-cmd --reload
    elif [ "$OS" = "Fedora" ]; then
        sudo firewall-cmd --permanent --add-port=80/tcp
        sudo firewall-cmd --permanent --add-port=443/tcp
        firewall-cmd --reload
    else
        echo "Unsupported OS: $OS"
    fi
}

selinux_rules() {
    if [ "$OS" = "RedHat" ]; then
        setsebool -P httpd_can_network_connect 1
    elif [ "$OS" = "Fedora" ]; then
        setsebool -P httpd_can_network_connect 1
    else
        echo "Unsupported OS: $OS Unable to Set SELinux Rule"
    fi
}

install_dependencies() {
    if [ "$OS" = "RedHat" ]; then
        if [ "$VER" = "8" ]; then
            sudo subscription-manager repos --enable ansible-2.9-rhel-8-x86_64
            sudo dnf install -y python39 python39-pip python39-devel git redis nginx openldap-devel ansible
        elif [ "$VER" = "9" ]; then
            sudo dnf install -y python39 python39-pip python39-devel git redis nginx openldap-devel ansible-core
        else
            echo "Unsupported OS Version: $VER"
        fi
    elif [ "$OS" = "Fedora" ]; then
        if [ "$VER" = "36" ]; then
            sudo dnf install -y python3 python3-pip python3-devel git redis nginx openldap-devel ansible-core
        else
            echo "Unsupported OS Version: $VER"
        fi
    else
        echo "Unsupported OS: $OS"
    fi
}

install_postgresql() {
    if [ "$OS" = "RedHat" ]; then
        if [ "$VER" = "8" ]; then
            sudo dnf install -y https://download.postgresql.org/pub/repos/yum/reporpms/EL-8-x86_64/pgdg-redhat-repo-latest.noarch.rpm
            sudo dnf -qy module disable postgresql
            sudo dnf install -y postgresql14-server
            sudo /usr/pgsql-14/bin/postgresql-14-setup initdb
            sudo systemctl enable --now postgresql-14
        elif [ "$VER" = "9" ]; then
            sudo dnf install -y https://download.postgresql.org/pub/repos/yum/reporpms/EL-9-x86_64/pgdg-redhat-repo-latest.noarch.rpm
            sudo dnf -qy module disable postgresql
            sudo /usr/pgsql-14/bin/postgresql-14-setup initdb
            sudo systemctl enable --now postgresql-14
        else
            echo "Unsupported OS Version: $VER"
        fi
    elif [ "$OS" = "Fedora" ]; then
        if [ "$VER" = "36" ]; then
            dnf install -y https://download.postgresql.org/pub/repos/yum/reporpms/F-36-x86_64/pgdg-fedora-repo-latest.noarch.rpm
            dnf install -y postgresql14-server
            sudo /usr/pgsql-14/bin/postgresql-14-setup initdb
            sudo systemctl enable --now postgresql-14
        else
            echo "Unsupported OS Version: $VER"
        fi
    else
        echo "Unsupported OS: $OS"
    fi
}
