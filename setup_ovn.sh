#!/bin/bash

rm -f /tmp/output.txt

ip=$(sudo ip a s eth1 | grep 172 | tr -s " "| cut -d " " -f 3 | cut -d "/" -f 1)
#echo $ip >> /tmp/output.txt


sudo systemctl start openvswitch

CENTRAL_IP=10.12.76.5
ENCAP_TYPE=geneve

sudo ovs-vsctl set Open_vSwitch . external_ids:ovn-remote="tcp:$CENTRAL_IP:6642" \
  external_ids:ovn-nb="tcp:$CENTRAL_IP:6641" \
  external_ids:ovn-encap-ip=$ip \
  external_ids:ovn-encap-type="$ENCAP_TYPE"
