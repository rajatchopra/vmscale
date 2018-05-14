#!/bin/bash

# Create /etc/hosts entries for the VMs
# add the report from running this to /etc/hosts

ips=$(virsh net-dhcp-leases default | gawk '/ipv4/{ print $5}' | sed 's;/24;;')

for ip in $ips
do
  fqn=$(ssh ${ip} hostname)
  host=$(echo ${fqn} | sed 's/wsfd-//
s/.ntdv.lab.eng.bos.redhat.com//
s/.example.com//')
  echo ${ip}  ${host}  ${fqn}
done

