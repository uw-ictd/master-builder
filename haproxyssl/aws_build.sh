#!/bin/sh

# Build local docker of haproxy-cert
docker build ./docker-haproxy-certbot -t djohnson/haproxy-certbot-wildcard-test

# Build the docker container (dont run in background)
HAPROXYSSL_IPV4=172.18.0.60 docker-compose up 

# Make directory for letsecnrypt and haproxy cfg
mkdir -p /mnt/data/haproxyssl
cp ./haproxy.cfg /mnt/data/haproxyssl
cp -ra ./letsencrypt /mnt/data/haproxyssl