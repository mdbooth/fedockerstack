#!/bin/sh

exec sudo docker build -t mbooth/devstack . "$@"
