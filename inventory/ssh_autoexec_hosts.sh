#!/bin/bash

for m in `cat ../node_list.txt`; do
    echo "$m.."
	echo  $(ssh -o StrictHostKeyChecking=no openshift@${m} $1)
done
