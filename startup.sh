#!/bin/bash

setup_docker_ce() {
echo $(date -Is) Setup Docker
dnf -y install epel-release
dnf -y install git htop
dnf -y config-manager --add-repo=https://download.docker.com/linux/centos/docker-ce.repo
dnf install docker-ce --nobest --allowerasing -y
systemctl enable --now docker
dnf -y install python3
pip3 install docker-compose
echo $(date -Is) Setup Docker OK
}

setup_docker_ce

chown 666 images/qm/*

docker-compose build

docker-compose up -d

chmod -R 777 data/

sleep 120

bash test.sh
