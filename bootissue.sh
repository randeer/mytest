#!/bin/bash

# NFS entry to add
entry="192.168.4.100:/mnt/db nfs defaults 0 0"

# Check if the entry already exists in /etc/fstab
if grep -Fxq "$entry" /etc/fstab; then
    echo "Entry already exists in /etc/fstab. No changes made."
else
    echo "$entry" | sudo tee -a /etc/fstab > /dev/null
    echo "Entry added to /etc/fstab."
fi
