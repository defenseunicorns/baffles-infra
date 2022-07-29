#!/bin/sh 

sudo yum install -y yum-utils
sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
sudo yum install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin qemu-kvm libvirt-daemon-kvm libvirt-client
sudo systemctl enable libvirtd --now
sudo systemctl enable docker --now
