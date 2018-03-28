#!/bin/bash

# Install python in each VM so ansible will work

NUM_VMS_PER_MACHINE=${NUM_VMS_PER_MACHINE:-5}

host=$(hostname)
short=$(hostname | cut -d "." -f 1 | cut -d "-" -f 2)
ips=$(virsh net-dhcp-leases default | grep ipv4 | tr -s " " | cut -d " " -f 6 | head -${NUM_VMS_PER_MACHINE} | cut -d "/" -f 1)
echo " " >> /etc/hosts

for i in ${ips}
do
  echo "On host ${i} install python"
  ssh $i dnf install -y python
done

exit 0

