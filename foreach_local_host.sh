#!/bin/bash

cd /data/src/vmscale
iplist=$(virsh net-dhcp-leases default | tail -n +3 | tr -s " " | cut -d " " -f 6 | head -4 | cut -d "/" -f 1)
hs=`hostname`
rm -f /tmp/output.txt


suffix=$(ip a s rcbr0 | grep 172 | tr -s " "| cut -d " " -f 3 | cut -d "/" -f 1 | cut -d "." -f 4)

ix=1
for ip in $iplist; do
	pub_ip=172.16.${ix}.${suffix}
	ssh -o StrictHostKeyChecking=no openshift@${ip} "sudo ip addr add ${pub_ip}/16 dev eth1"
	ssh -o StrictHostKeyChecking=no openshift@${ip} "sudo ip link set dev eth1 up"
	output=$(ssh -o StrictHostKeyChecking=no openshift@${ip} "sudo ip a s eth1")
	echo $output >> /tmp/output.txt
	ix=$((ix + 1))
done
