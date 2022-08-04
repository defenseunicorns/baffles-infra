#!/bin/sh 

sudo cp -f /tmp/usr.sbin.libvirtd /etc/apparmor.d/usr.sbin.libvirtd
sudo systemctl reload apparmor

# Tasks to mount additional storage
# The following steps were taken from this site: https://cloud.google.com/compute/docs/disks/add-persistent-disk

sudo mkfs.ext4 -m 0 -E lazy_itable_init=0,lazy_journal_init=0,discard /dev/sdb
sudo mkdir -p /var/lib/rancher/k3s/storage/
sudo mount -o discard,defaults /dev/sdb /var/lib/rancher/k3s/storage/
sudo chmod a+w /var/lib/rancher/k3s/storage/
sudo cp /etc/fstab /etc/fstab.backup
sudo echo "UUID=$(sudo blkid /dev/sdb | cut -d'"' -f 2) /var/lib/rancher/k3s/storage/ ext4 discard,defaults,nofail 0 2" | sudo tee -a /etc/fstab
