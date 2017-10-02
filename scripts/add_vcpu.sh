#!/bin/bash

NUM_VMS_PER_MACHINE=${NUM_VMS_PER_MACHINE:-4}

MACHINE_PREFIX=`hostname`
for i in `seq 1 ${NUM_VMS_PER_MACHINE}`
do
  NODE_NAME=${MACHINE_PREFIX}_${i}
  virsh setvcpus ${NODE_NAME} 4
done
