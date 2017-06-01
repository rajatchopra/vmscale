#!/bin/bash

for m in `cat machines_ip.txt`; do
    echo "$m.."
	echo  $(ssh -o StrictHostKeyChecking=no root@${m} $1)
done
