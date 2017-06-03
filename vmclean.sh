#!/bin/bash

NUM_VMS_PER_MACHINE=${NUM_VMS_PER_MACHINE:-4}

cd /data/src/vmscale
mkdir -p libvirt_storage
cd libvirt_storage
export STORAGE_PATH=`pwd`

MACHINE_PREFIX=`hostname`
for i in `seq 1 ${NUM_VMS_PER_MACHINE}`
do
  NODE_NAME=${MACHINE_PREFIX}_${i}
  virsh destroy ${NODE_NAME}
  virsh undefine ${NODE_NAME}
  virsh pool-destroy ${NODE_NAME}_config
  virsh pool-delete ${NODE_NAME}_config
done

cd ..

## Delete the storage pool
virsh pool-destroy ovn-kubernetes
virsh pool-delete ovn-kubernetes
virsh pool-destroy libvirt_storage
virsh pool-delete libvirt_storage
