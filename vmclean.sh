#!/bin/bash

NUM_VMS_PER_MACHINE=${NUM_VMS_PER_MACHINE:4}

mkdir -p libvirt_storage
cd libvirt_storage
export STORAGE_PATH=`pwd`

## Delete the storage pool
virsh pool-destroy ovn-kubernetes
virsh pool-delete ovn-kubernetes

MACHINE_PREFIX=`hostname`
for i in `seq 1 ${NUM_VMS_PER_MACHINE}`
do
  NODE_NAME=${MACHINE_PREFIX}_${i}
  virsh destroy ${NODE_NAME}
  virsh undefine ${NODE_NAME}
done

brctl delbr rcbr0
