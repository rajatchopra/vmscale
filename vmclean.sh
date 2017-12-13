#!/bin/bash

NUM_VMS_PER_MACHINE=${NUM_VMS_PER_MACHINE:-5}

PROJECT_NAME=${PROJECT_NAME:-ovn-kubernetes}

cd /data/src/vmscale
mkdir -p libvirt_storage
cd libvirt_storage
export STORAGE_PATH=`pwd`

MACHINE_PREFIX=`hostname`
for i in `seq 1 ${NUM_VMS_PER_MACHINE}`
do
  NODE_NAME=${MACHINE_PREFIX}-${i}
  virsh destroy ${NODE_NAME}
  virsh undefine ${NODE_NAME}
  virsh pool-destroy ${NODE_NAME}_config
  rm -rf ${NODE_NAME}*
  virsh pool-delete ${NODE_NAME}_config
  virsh pool-undefine ${NODE_NAME}_config
done

cd ..

## Delete the storage pool
virsh pool-destroy ${PROJECT_NAME}
virsh pool-delete ${PROJECT_NAME}
virsh pool-undefine ${PROJECT_NAME}
