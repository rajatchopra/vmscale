#!/bin/bash

NUM_VMS_PER_MACHINE=${NUM_VMS_PER_MACHINE:-5}

host=$(hostname)
short=$(hostname | cut -d "." -f 1 | cut -d "-" -f 2)
ips=$(virsh net-dhcp-leases default | grep ipv4 | tr -s " " | cut -d " " -f 6 | head -${NUM_VMS_PER_MACHINE} | cut -d "/" -f 1)
echo " " >> /etc/hosts

for i in ${ips}
do
  hname=$(ssh $i hostname)
  ind=$(echo ${hname} | sed "s/${host}-//" | sed 's/.example.com//')
  echo "$i  ${short}-${ind}  ${hname}" >> /etc/hosts
  ssh ${hname} echo 1
  ssh ${short}-${ind} echo 2
done
exit 0

