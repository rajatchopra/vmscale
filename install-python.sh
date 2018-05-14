#!/bin/bash

# install python on each vm

hosts=$(gawk '/192.168.122/{ print $2 }' /etc/hosts)

for host in ${hosts}
do
  echo "  "
  echo "   INSTALLING PYTHON ON --------  ${host} ----------"
  ssh ${host} dnf install -y python
done
