# Postgresql Container
# https://catalog.redhat.com/software/containers/rhel8/postgresql-13/5ffdbdef73a65398111b8362
sudo podman run -d --volume /srv/repo:/repo:z --label=repo --hostname=myhostname --net myCNInetwork --ip X.X.X.X --dns=X.X.X.X --dns-search=my.domain --name=mycontainername -e POSTGRESQL_USER=user -e POSTGRESQL_PASSWORD=pass -e POSTGRESQL_DATABASE=nautobot registry.redhat.io/rhel8/postgresql-13
 
# Redis Container
# https://catalog.redhat.com/software/containers/rhel8/redis-6/6065b06cdfe097aa13042b50
sudo podman run -d --volume /srv/repo:/repo:z --label=repo --hostname=myhostname --net myCNInetwork --ip X.X.X.X --dns=X.X.X.X --dns-search=my.domain --name=mycontainername -e REDIS_PASSWORD=strongpassword registry.redhat.io/rhel8/redis-6
 
# Nautobot Container
sudo podman run -d --volume /srv/repo:/repo:z --label=repo --hostname=myhostname --net myCNInetwork --ip X.X.X.X --dns=X.X.X.X --dns-search=my.domain --name=mycontainername localhost/nautobot