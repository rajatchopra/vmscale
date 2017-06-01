#!/bin/bash

passwd=${PASSWD:-"password123"}

for m in `cat machines_ip.txt`; do
    echo "$m.."
	echo  $(sshpass -p $passwd ssh -o StrictHostKeyChecking=no root@${m} $1)
done
