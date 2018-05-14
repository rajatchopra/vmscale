#!/bin/bash

# Try to ssh to each host and fqn of the VMs from the /etc/hosts file

hosts=$(gawk '/192.168.122/{ print $2 "  " $3 }' /etc/hosts)

for host in ${hosts}
do
  echo trying $host
  ssh $host exit
done
