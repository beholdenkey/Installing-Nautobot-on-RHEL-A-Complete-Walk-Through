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
    if [ "$OS" = "Red Hat Enterprise Linux" ]; then
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
    if [ "$OS" = "Red Hat Enterprise Linux" ]; then
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
    if [ "$OS" = "Red Hat Enterprise Linux" ]; then
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
    if [ "$OS" = "Red Hat Enterprise Linux" ]; then
        setsebool -P httpd_can_network_connect 1
    elif [ "$OS" = "Fedora" ]; then
        setsebool -P httpd_can_network_connect 1
    else
        echo "Unsupported OS: $OS Unable to Set SELinux Rule"
    fi
}

install_dependencies() {
    if [ "$OS" = "Red Hat Enterprise Linux" ]; then
        if [ "$VER" = "8.0" ]; then
            sudo subscription-manager repos --enable ansible-2.9-rhel-8-x86_64
            sudo dnf install -y python3 python3-pip python3-devel git redis nginx openldap-devel ansible
        elif [ "$VER" = "9.0" ]; then
            sudo dnf install -y python3 python3-pip python3-devel git redis nginx openldap-devel ansible-core
        else
            echo "Unsupported OS Version: $VER"
        fi
    elif [ "$OS" = "Fedora" ]; then
        if [ "$VER" = "36.0" ]; then
            sudo dnf install -y python3 python3-pip python3-devel git redis nginx openldap-devel ansible-core
        else
            echo "Unsupported OS Version: $VER"
        fi
    else
        echo "Unsupported OS: $OS"
    fi
}

install_postgresql() {
    if [ "$OS" = "Red Hat Enterprise Linux" ]; then
        if [ "$VER" = "8.0" ]; then
            sudo dnf install -y https://download.postgresql.org/pub/repos/yum/reporpms/EL-8-x86_64/pgdg-redhat-repo-latest.noarch.rpm
            sudo dnf install -y postgresql14-server
            sudo /usr/pgsql-14/bin/postgresql-14-setup initdb
            sudo systemctl enable --now postgresql-14
        elif [ "$VER" = "9.0" ]; then
            sudo dnf install -y https://download.postgresql.org/pub/repos/yum/reporpms/EL-9-x86_64/pgdg-redhat-repo-latest.noarch.rpm
            sudo /usr/pgsql-14/bin/postgresql-14-setup initdb
            sudo systemctl enable --now postgresql-14
        else
            echo "Unsupported OS Version: $VER"
        fi
    elif [ "$OS" = "Fedora" ]; then
        if [ "$VER" = "36.0" ]; then
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

configure_postgres_conf() {
    if [ "$OS" = "Red Hat Enterprise Linux" ]; then
        if [ "$VER" = "8.0" ]; then
            sudo cp /etc/postgresql/14/main/postgresql.conf /etc/postgresql/14/main/postgresql.conf.bak
            sudo sed -i 's/#password_encryption = on/password_encryption = scram-sha-256/g' /etc/postgresql/14/main/postgresql.conf
        elif [ "$VER" = "9.0" ]; then
            sudo cp /etc/postgresql/14/main/postgresql.conf /etc/postgresql/14/main/postgresql.conf.bak
            sudo sed -i 's/#password_encryption = on/password_encryption = scram-sha-256/g' /etc/postgresql/14/main/postgresql.conf
            sudo systemctl restart postgresql-14
        else
            echo "Unsupported OS Version: $VER"
        fi
    elif [ "$OS" = "Fedora" ]; then
        if [ "$VER" = "36.0" ]; then
            sudo cp /etc/postgresql/14/main/postgresql.conf /etc/postgresql/14/main/postgresql.conf.bak
            sudo sed -i 's/#password_encryption = on/password_encryption = scram-sha-256/g' /etc/postgresql/14/main/postgresql.conf
            sudo systemctl restart postgresql-14
        else
            echo "Unsupported OS Version: $VER"
        fi
    else
        echo "Unsupported OS: $OS"
    fi

}

check_pghba() {
    if [ "$OS" = "Red Hat Enterprise Linux" ]; then
        if [ "$VER" = "8.0" ]; then
            sudo cp /etc/postgresql/14/main/pg_hba.conf /etc/postgresql/14/main/pg_hba.conf.bak
            sudo sed -i 's/local   all             all                                     peer/local   all             all                                     scram-256/g' /etc/postgresql/14/main/pg_hba.conf
            sudo sed -i 's/host    all             all                                                                                                          scram-256/g' /ect/postgresql/14/main/pg_hba/conf
        elif [ "$VER" = "9.0" ]; then
            sudo cp /etc/postgresql/14/main/pg_hba.conf /etc/postgresql/14/main/pg_hba.conf.bak
            sudo sed -i 's/local   all             all                                     peer/local   all             all                                     scram-256/g' /etc/postgresql/14/main/pg_hba.conf
            sudo sed -i 's/host    all             all                                                                                                          scram-256/g' /ect/postgresql/14/main/pg_hba/conf
            sudo systemctl restart postgresql-14
        else
            echo "Unsupported OS Version: $VER"
        fi
    elif [ "$OS" = "Fedora" ]; then
        if [ "$VER" = "36.0" ]; then
            sudo cp /etc/postgresql/14/main/pg_hba.conf /etc/postgresql/14/main/pg_hba.conf.bak
            sudo sed -i 's/local   all             all                                     peer/local   all             all                                     scram-256/g' /etc/postgresql/14/main/pg_hba.conf
            sudo sed -i 's/host    all             all                                                                                                          scram-256/g' /ect/postgresql/14/main/pg_hba/conf
            sudo systemctl restart postgresql-14
        fi
    else
        echo "Unsupported OS: $OS"
    fi
}

configure_postgresql_db() {
    if [ "$OS" = "Red Hat Enterprise Linux" ]; then
        if [ "$VER" = "8.0" ]; then
            sudo systemctl start postgresql-14
            sudo systemctl enable postgresql-14
            sudo -u postgres psql -c "CREATE USER nautobot WITH PASSWORD 'P@ssw0rd12';"
            sudo -u postgres psql -c "CREATE DATABASE nautobot;"
            sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE nautobot TO nautobot;"
        elif [ "$VER" = "9.0" ]; then
            sudo systemctl start postgresql-14
            sudo systemctl enable postgresql-14
            sudo -u postgres psql -c "CREATE USER nautobot WITH PASSWORD 'P@ssw0rd12';"
            sudo -u postgres psql -c "CREATE DATABASE nautobot;"
            sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE nautobot TO nautobot;"
        else
            echo "Unsupported OS Version: $VER"
        fi
    elif [ "$OS" = "Fedora" ]; then
        if [ "$VER" = "36.0" ]; then
            sudo systemctl start postgresql-14
            sudo systemctl enable postgresql-14
            sudo -u postgres psql -c "CREATE USER nautobot WITH PASSWORD 'P@ssw0rd12';"
            sudo -u postgres psql -c "CREATE DATABASE nautobot;"
            sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE nautobot TO nautobot;"
        else
            echo "Unsupported OS Version: $VER"
        fi
    else
        echo "Unsupported OS: $OS"
    fi
}

main() {
    detect_os
    disable_kdump
    update_os
    verify_system
    firewall_setup
    firewall_rules
    selinux_rules
    install_dependencies
    install_postgresql
    configure_postgres_conf
    check_pghba
    configure_postgresql_db
}

main
