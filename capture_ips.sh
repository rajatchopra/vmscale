#!/bin/bash

cd /data/src/vmscale
iplist=$(virsh net-dhcp-leases default | tail -n +3 | tr -s " " | cut -d " " -f 6 | head -4 | cut -d "/" -f 1)
hs=`hostname`
mkdir inventory/${hs}
touch inventory/${hs}/local_hosts
for ip in $iplist; do
	echo $ip >> inventory/local_hosts
done
