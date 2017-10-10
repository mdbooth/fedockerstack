#/bin/sh

exec sudo docker run -t -d \
                     --name devstack \
                     -v devstack-home:/home \
                     --privileged \
                     -v /sys/fs/cgroup:/sys/fs/cgroup:ro \
                     -v /dev:/dev \
                     mbooth/devstack
