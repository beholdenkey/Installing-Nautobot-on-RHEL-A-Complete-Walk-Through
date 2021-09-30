# Creating and Running Podman Containers (Rootfull)

# Get available container images (See Buildah Page)
sudo podman images
REPOSITORY                                      TAG     IMAGE ID      CREATED       SIZE
localhost/my_image_name                         latest  2a21f10507b8  4 days ago    570 MB
sat68.s3i.org:5000/udn-red_hat_containers-ubi8  latest  3269c37eae33  7 weeks ago   208 MB
 
 
# Get available networks
# Must ensure that you see your network listed
sudo podman network ls
NAME        VERSION  PLUGINS
podman        0.4.0    bridge,portmap,firewall,tuning
test1_net     0.4.0    macvlan,tuning
test2_bridge  0.4.0    bridge,tuning
 
# Create and Run a Container
# -ti = (t) creates a tty connection to the container, (i) allows the administrator to interact with container
# --volume = will attach directory to the container as a volume. (Z) passes SELINUX information to resolve necessary permissions
# --label = provides the name of the volume, this is typically required by SELINUX in order for the volume to become attached
# --hostname = what do you want the hostname within the container to be?
# --net = pulls configuration from available networks (listed above)
# --ip = assigns static IP to container (IP must be in the scope of the network). Network configuration for rootfull is located in /etc/cni/net.d
# --name = How you want podman to reference the container. Otherwise, a random generate name will be provided.
# Lastly provide image name that you want to use
# This is not an exhaustive list of commands, please see http://docs.podman.io/en/latest/Commands.html
sudo podman run -ti --volume /srv/repo:/repo:Z --label=repo --hostname=container_OS_hostname --net test1_net --ip 10.1.0.1 --name podman_container_name localhost/my_image_name
 
# Get Container Information and Status
sudo podman ps -a
CONTAINER ID  IMAGE                           COMMAND     CREATED     STATUS           PORTS   NAMES
913556a78ef7  localhost/my_image_name:latest  /sbin/init  4 days ago  Up 22 hours ago          ztp1
 
# Stop Container
sudo podman stop
 
# Start Container
sudo podman start
 
# Interactive TTY with Container
sudo podman exec -it my_image_name /bin/bash
 
# Remove Container
sudo podman rm my_image_name
 
# Remove Images
sudo podman rmi my_image_name
 
# Add Public Volume (small z)
 
# Adjusting TMPFS /tmp directory to 12G
sudo podman run -ti --volume /srv/repo:/repo:z --label=repo --hostname=container_OS_hostname --net test1_net --ip 10.1.0.1 --name podman_container_name localhost/my_image_name
 
# Add Private Volume (Z)
 
sudo podman run -ti --volume /srv/repo:/repo:Z --label=repo --hostname=container_OS_hostname --net test1_net --ip 10.1.0.1 --name podman_container_name localhost/my_image_name
 
 
# Adjusting TMPFS /tmp (Read and Write and Increase Size) directory to 12G
sudo podman run -ti --volume /srv/repo:/repo:z --label=repo --tmpfs /tmp:rw,size=12000000k,mode=1777 --hostname=container_OS_hostname --net test1_net --ip 10.1.0.1 --name podman_container_name localhost/my_image_name