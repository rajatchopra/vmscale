#!/bin/bash

rm -f /tmp/output.txt

ip=$(sudo ip a s eth1 | grep 172 | tr -s " "| cut -d " " -f 3 | cut -d "/" -f 1)
#echo $ip >> /tmp/output.txt


cd /home/openshift/ovn-kubernetes/go-controller
export PATH=$PATH:/usr/local/go/bin
make
sudo make install

