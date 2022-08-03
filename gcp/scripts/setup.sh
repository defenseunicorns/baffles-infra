#!/bin/sh 

sudo cp -f /tmp/usr.sbin.libvirtd /etc/apparmor.d/usr.sbin.libvirtd
sudo systemctl reload apparmor
