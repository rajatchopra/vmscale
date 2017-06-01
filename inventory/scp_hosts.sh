#!/bin/bash

for m in `cat machines_ip.txt`; do
	echo  $(scp -o StrictHostKeyChecking=no $1 root@${m}:$2)
done
