#!/bin/bash

NUM_VMS_PER_MACHINE=${NUM_VMS_PER_MACHINE:-4}

install_pkgs() {
	dnf -y groupinstall Virtualization
}

mkdir -p libvirt_storage
cd libvirt_storage
export STORAGE_PATH=`pwd`
if [ ! -f CentOS-7-x86_64-GenericCloud.qcow2 ]; then
  wget http://cloud.centos.org/centos/7/images/CentOS-7-x86_64-GenericCloud.qcow2.xz
  unxz CentOS-7-x86_64-GenericCloud.qcow2.xz
fi

## Create a storage pool
# https://docs.fedoraproject.org/en-US/Fedora/18/html/Virtualization_Administration_Guide/chap-Virtualization_Administration_Guide-Storage_Pools-Storage_Pools.html
virsh pool-define-as --type dir --name ovn-kubernetes --target ${STORAGE_PATH}
virsh pool-start ovn-kubernetes
virsh pool-autostart ovn-kubernetes
virsh pool-refresh ovn-kubernetes
ip a s rcbr0
retcode=$?
if [ $retcode -ne 0 ]; then
  virsh iface-bridge em1 rcbr0
fi


MACHINE_PREFIX=`hostname`
echo "Creating ${NUM_VMS_PER_MACHINE} machines:"
for i in `seq 1 ${NUM_VMS_PER_MACHINE}`
do
  echo "Creating machine number $i"
  NODE_NAME=${MACHINE_PREFIX}_${i}
  ## Create the boot iso
  mkdir -p ${NODE_NAME}_config
  pushd ${NODE_NAME}_config
  cp ../../user_data user-data
  cp ../../meta_data meta-data
  sed -i s/NODE_NAME/${NODE_NAME}/ user-data
  sed -i s/NODE_NAME/${NODE_NAME}/ meta-data
  genisoimage -output ${NODE_NAME}_cloud-init.iso -volid cidata -joliet -rock user-data meta-data
  virsh vol-create-as ovn-kubernetes ${NODE_NAME}.qcow2 20G --format qcow2 --backing-vol ${STORAGE_PATH}/CentOS-7-x86_64-GenericCloud.qcow2 --backing-vol-format qcow2
  virt-install --connect qemu:///system --ram 10240 -n ${NODE_NAME} --os-type=linux --os-variant=rhel7  --disk path=${STORAGE_PATH}/${NODE_NAME}.qcow2,device=disk,bus=virtio,format=qcow2 --disk path=${STORAGE_PATH}/${NODE_NAME}_config/${NODE_NAME}_cloud-init.iso,device=cdrom,bus=virtio,format=iso --vcpus=2 --graphics spice --noautoconsole --import
  virsh attach-interface --domain ${NODE_NAME} --type bridge --source rcbr0 --config --live
  popd
  echo "Done creating machine number $i"
done
