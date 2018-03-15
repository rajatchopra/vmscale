#!/bin/bash

# vmscale is expected to be cloned in /root
# libvirt_storage created in the clone (/root/vmscale/libvirt_storage)
# Fedora-Cloud-Base-Rawhide-20180204.n.0.x86_64.qcow2 is current as of this time.
# it changes daily.
#
# This is done on fedora rawhide Server because it has ovs-2.8.1 and
# openvswitch-ovn-kubernetesi0.1.0 which are both required. It also has a 
# Server has a small /root that can be expanded to the rest of the disk for
# libvirt_storage for the VMs.
#
# NOTE:
# At some point RHEL will have the needed parts and this will be obsolete. 
# At present ovs-2.74 is in fast datapath
# and openvswitch-ovn-kubernetes-0.1.0 is in the ocp puddle.

NUM_VMS_PER_MACHINE=${NUM_VMS_PER_MACHINE:-5}


## 
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
INSTALL_DIR=${INSTALL_DIR:-${SCRIPT_DIR}}
QCOW_INSTALL_DIR=${QCOW_INSTALL_DIR:-${INSTALL_DIR}}
PROJECT_NAME=${PROJECT_NAME:-ovn-kubernetes}
STORAGE_DIR=${STORAGE_DIR:-libvirt_storage}
VM_DIR=${VM_DIR:-${STORAGE_DIR}}

##
install_pkgs() {
	dnf -y groupinstall Virtualization
	dnf -y install genisoimage
	# systemctl start libvirtd
	# systemctl enable libvirtd

}

export STORAGE_PATH=${QCOW_INSTALL_DIR}/${STORAGE_DIR}
mkdir -p ${STORAGE_PATH}
pushd ${STORAGE_PATH}

#if [ ! -f CentOS-7-x86_64-GenericCloud.qcow2 ]; then
  #wget http://cloud.centos.org/centos/7/images/CentOS-7-x86_64-GenericCloud.qcow2.xz
  #unxz CentOS-7-x86_64-GenericCloud.qcow2.xz
#fi
if [ ! -f Fedora-Cloud-Base-27-1.6.x86_64.qcow2 ]; then
  wget https://dl.fedoraproject.org/pub/fedora/linux/releases/27/CloudImages/x86_64/images/Fedora-Cloud-Base-27-1.6.x86_64.qcow2
fi

popd

VM_PATH=${INSTALL_DIR}/${VM_DIR}
mkdir -p ${VM_PATH}
pushd ${VM_PATH}

## Create a storage pool
# https://docs.fedoraproject.org/en-US/Fedora/18/html/Virtualization_Administration_Guide/chap-Virtualization_Administration_Guide-Storage_Pools-Storage_Pools.html
virsh pool-define-as --type dir --name ${PROJECT_NAME} --target ${STORAGE_PATH}
virsh pool-start ${PROJECT_NAME}
virsh pool-autostart ${PROJECT_NAME}
virsh pool-refresh ${PROJECT_NAME}
#ip a s rcbr0
#retcode=$?
#if [ $retcode -ne 0 ]; then
#  virsh iface-bridge em1 rcbr0
#fi


MACHINE_PREFIX=`hostname`
echo "Creating ${NUM_VMS_PER_MACHINE} machines:"
for i in `seq 1 ${NUM_VMS_PER_MACHINE}`
do
  echo "Creating machine number $i"
  NODE_NAME=${MACHINE_PREFIX}-${i}
  ## Create the boot iso
  mkdir -p ${NODE_NAME}_config
  pushd ${NODE_NAME}_config
  cp ${SCRIPT_DIR}/user_data user-data
  cp ${SCRIPT_DIR}/meta_data meta-data
  sed -i s/NODE_NAME/${NODE_NAME}/ user-data
  sed -i s/NODE_NAME/${NODE_NAME}/ meta-data
  genisoimage -output ${NODE_NAME}_cloud-init.iso -volid cidata -joliet -rock user-data meta-data
  #virsh vol-create-as ${PROJECT_NAME} ${NODE_NAME}.qcow2 60G --format qcow2 --backing-vol ${STORAGE_PATH}/CentOS-7-x86_64-GenericCloud.qcow2 --backing-vol-format qcow2
  virsh vol-create-as ${PROJECT_NAME} ${NODE_NAME}.qcow2 120G --format qcow2 --backing-vol ${STORAGE_PATH}/Fedora-Cloud-Base-27-1.6.x86_64.qcow2 --backing-vol-format qcow2
  virt-install --connect qemu:///system --ram 18432 -n ${NODE_NAME} --os-type=linux --os-variant=rhel7  --disk path=${VM_PATH}/${NODE_NAME}.qcow2,device=disk,bus=virtio,format=qcow2 --disk path=${VM_PATH}/${NODE_NAME}_config/${NODE_NAME}_cloud-init.iso,device=cdrom,bus=virtio,format=iso --vcpus=2 --graphics spice --noautoconsole --import
  #virsh attach-interface --domain ${NODE_NAME} --type bridge --source rcbr0 --config --live
  popd
  echo "Done creating machine number $i"
done
