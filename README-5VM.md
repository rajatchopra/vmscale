20171208

Install 5VM cluster on 1 physical (beaker) host
Host is a Dell R730 with 4 port NIC card, 256Gb disk.

The host and VMs are provisioned with Fedora-rawhide Server
Fedora-rawhide was selected bacause it includes ovs/ovn 2.8, and
openvswitch-ovn-kubernetes-0.1.0 which are required.
Server has a small /root that can be expanded and no /home

openvswitch-ovn-kubernetes-0.1.0 is in rawhide and will make it
into fedora-28, 27. It is in the the OCP puddle. At present
fastdatapath has openvswitch 2.7.4 which prevents us from using RHEL.

THE PHYSICAL HOST:

The physical host is from a pool of hosts on beaker:
wsfd-netdev31.ntdv.lab.eng.bos.redhat.com
fedora-rawhide Server will be installed and /root will be expanded to 
fill the 256Gb disk.
5 VMs will be created on it and the cluster will have a node per VM.

Beaker is used to provision the physical host with Fedora-rawhide Server
Beaker allocates a very small "/" partition which doesn't support the
needed VMs. So part of the install is to expand root to use the rest
of the disk.

The host is setup using a combination of ansible scripts and manual
configuration. This can be made more automated in the future.

===================================
Install and configure the host:

Beaker is used to provision the host.
https://beaker.engineering.redhat.com/
login:
Under the hello, ... tab, My Systems shows a list of your systems
Click on the host and reserve it.
Click provision:
Select Family Fedora-rawhide
select Distro Tree Fedora-rawhide-20180204.n.1 Server x86_64
Click Provision

When this is done the host will be running Fedora-rawhide
Your default ssh key will be installed the host and the 
default root password will be installed.

===================================
Provisioning the host:
  The cluster will be in a set of VMs on the host.

After beaker is done, ssh to netdev31 and...

Install ansible:
# pip3 install ansible
or
# dnf install ansible

Create a ssh key pair:
# ssh-keygen
Use ssh-copy-id to copy the key to each of the hosts. ssh login to
each of the hosts to make sure it works without passwords or prompts.

Fedora Server provisions a very small root (15Gb). The following expands it
to 235 which is enough to support the VMs. When the host runs out of 
disk space the VMs pause until more space is available.
# lvextend --size +220G /dev/mapper/fedora-root ; xfs_growfs /


libvirt will store the VMs here
# chmod 755 /root
# cd /root/vmscale
# mkdir libvirt_storage
# chown -R 107.107 libvirt_storage

Install, enable and start libvirtd
# dnf -y groupinstall Virtualization
# dnf install genisoimage

# systemctl start libvirtd
# systemctl enable libvirtd


# dnf install wget

Clone vmscale
# dnf install git

# git clone https://github.com/rajatchopra/vmscale on the master.
# cd  vmscale

Caveat:
I have a fork of vmscale that I work with. So I use:
.git/config
...
[remote "upstream"]
        url = https://github.com/rajatchopra/vmscale
        fetch = +refs/heads/*:refs/remotes/origin/*
        fetch = +refs/pull/*/head:refs/remotes/upstream/pr/*
[remote "origin"]
        url = https://github.com/pecameron/vmscale
        fetch = +refs/heads/*:refs/remotes/origin/*
...


Edit file user_data to add the generated public key (above) in two
places in the file.  Ansible, in  a later step will copy this to
each VM so you will be able to ssh to each VM.

Edit the desired qcow2 file name, e.g,
https://dl.fedoraproject.org/pub/fedora/linux/development/rawhide/CloudImages/x86_64/images/Fedora-Cloud-Base-Rawhide-20180204.n.0.x86_64.qcow2
into vwget section and in the "virsh vol-create-as" section in the vmcreate.sh file.
rawhide is built every day so the version changes every day. 

Also, change NUM_VMS_PER_MACHINE to the number of nodes/host
e.g., NUM_VMS_PER_MACHINE=${NUM_VMS_PER_MACHINE:-5}
in both vmcreate.sh and vmclean.sh


==================
ANSIBLE:
Ansible is used to bring up the VMs.

Ansible requires python. This is not installed
as part of Fedora-27 Server.

# dnf install -y python


==================
Install the 5 VMs that will be the nodes:

edit vmcreate.sh to reference correct Fedora image in the wget section 
and in the "virsh vol-create-as" section
Run vmcreate.sh to create the 5 VMs

# cd ~/vmscale
# ./vmcreate.sh

# virsh list
 Id    Name                           State
----------------------------------------------------
 6     wsfd-netdev31.ntdv.lab.eng.bos.redhat.com-1 running
 7     wsfd-netdev31.ntdv.lab.eng.bos.redhat.com-2 running
 8     wsfd-netdev31.ntdv.lab.eng.bos.redhat.com-3 running
 9     wsfd-netdev31.ntdv.lab.eng.bos.redhat.com-4 running
 10    wsfd-netdev31.ntdv.lab.eng.bos.redhat.com-5 running

Manually configure the network on each of the 5 VMs on the host

Manual configuration:
ssh to each host in turn.
# ssh 192.168.122.137 hostname
wsfd-netdev31.ntdv.lab.eng.bos.redhat.com-3.example.com

Find the IP addresses:
# virsh net-dhcp-leases default
 Expiry Time          MAC address        Protocol  IP address          Hostname  Client ID or DUID
-------------------------------------------------------------------------------------------------------
 2018-02-05 15:58:26  52:54:00:11:ab:e0  ipv4      192.168.122.137/24  -         ff:00:11:ab:e0:00:04:8a:4d:ed:1e:08:ae:42:91:8c:99:19:78:c3:84:23:93
 2018-02-05 15:58:19  52:54:00:20:25:55  ipv4      192.168.122.103/24  -         ff:00:20:25:55:00:04:c3:60:21:61:c6:42:47:42:89:80:aa:46:1a:52:1c:2a
 2018-02-05 15:58:26  52:54:00:61:1f:59  ipv4      192.168.122.193/24  -         ff:00:61:1f:59:00:04:5b:38:ce:ff:38:02:48:e9:a2:0e:83:0a:c0:cc:b5:d3
 2018-02-05 15:58:26  52:54:00:c5:7e:17  ipv4      192.168.122.135/24  -         ff:00:c5:7e:17:00:04:c5:b6:14:c3:c6:9a:4b:50:8d:30:a5:a3:95:c2:cc:99
 2018-02-05 15:58:26  52:54:00:f1:93:40  ipv4      192.168.122.38/24   -         ff:00:f1:93:40:00:04:ff:c1:25:61:99:0f:46:a8:ba:0c:d8:ca:7e:f9:91:b8

ssh to each address and note the VM name
Add a line to /etc/hosts
echo 192.168.122.137 netdev31-3 >> /etc/hosts
This allows easy future access by name:
# ssh netdev31-3

# cat /etc/hosts
127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4
::1         localhost localhost.localdomain localhost6 localhost6.localdomain6

192.168.122.137 netdev31-3 wsfd-netdev31.ntdv.lab.eng.bos.redhat.com-3.example.com
192.168.122.103 netdev31-1 wsfd-netdev31.ntdv.lab.eng.bos.redhat.com-1.example.com
192.168.122.193 netdev31-2 wsfd-netdev31.ntdv.lab.eng.bos.redhat.com-2.example.com
192.168.122.135 netdev31-5 wsfd-netdev31.ntdv.lab.eng.bos.redhat.com-5.example.com
192.168.122.38  netdev31-4 wsfd-netdev31.ntdv.lab.eng.bos.redhat.com-4.example.com


Verify that master can ssh to all of the VMs without password. E.g.,

The cluster will be the 5 VMs that you just verified.

============================
On master:
openvswitch-ovn-kubernetes is available in fedora rawhide

============================
Provision each VM to be part of the cluster:

The VMs are up and the master can reach each of them so at this
point we can provision the VMs to be part of the future cluster.

Install python on each vm. Ansible requires this to work, e.g.,
# ssh netdev31-1 dnf install -y python

hosts5run      - script to run ansible-playbook
hosts5play.yml - the playbook
hosts5         - the set of hosts

hosts5play.yml does the following on each VM:
- install ansible
- install packages from the various repos (beaker-fedora and fedora)
- add the 172.30.0.0/16 CIDR to the insecure registries token
- add the brew-pulp-docker01.web.prod.ext.phx2.redhat.com:8888 
  and registry.ops.openshift.com registries as insecure.
- restart docker
- restart the ovn-controller
- copy /etc/hosts to each VM - gives names and IP of all nodes
- set permissions on the excutables/scripts
- Add iptables firewall rules for ovn ports 6641 and 6642
- Ensure GENEVE's UDP port, 6081, isn't firewalled

At this point we are ready to install Openshift. It won't start
properly until ovnkube is run configuring Openshift to ovn.

===================================
Install Openshift

The Openshift install is done using playbooks that are found in 
an Openshift development puddle.

Get the repo:
# cat > /etc/yum.repos.d/openshift_additional.repo < EOF
[AtomicOpenShift-3.9-Puddle]
name=AtomicOpenShift-3.9-Puddle
baseurl=http://download.lab.bos.redhat.com/rcm-guest/puddles/RHAOS/AtomicOpenShift/3.9/latest/$basearch/os
gpgcheck=0
enabled=1

EOF

# dnf install \
openshift-ansible \
openshift-ansible-docs \
openshift-ansible-playbooks \
openshift-ansible-roles

The osehosts file:
This file directs the install. There are several items to consider.

At present we have tested with 1 master and 1 etcd

Install Openshift from the puddle using CNI (ovn)
(The install required python3)
./run5ose


========================
When master and etcd are up:

See if api is running
# ssh netdev31-1 oc get --raw /healthz/ready
ok

# ssh netdev31-1 oc get serviceaccount
# ssh netdev31-1 oc create serviceaccount ovn

# ssh netdev31-1 oc adm policy add-cluster-role-to-user cluster-admin -z ovn
# ssh netdev31-1 oc adm policy add-scc-to-user anyuid -z ovn
# ssh netdev31-1 oc sa get-token ovn  > /etc/origin/master/ovn.token

Manually create the /etc/sysconfig/ovn-kubernetes file.
Get the needed information from the openshift master.
Copy the file to each node. Masters and nodes use the same file. 
Restart the ovn-kubernetes-master.service on the ovn master and on each node
restart the ovn-kubernetes-node.service 

templates/ovn-kubernetes-master-setup.sh.j2 
is script that can be run on master to fill in the data.


==================

With the above the master ovnkube controller will initialize the central
master logical router and establish the watcher loops for the following:
 - nodes: as new nodes are born and init-node is called, the logical
   switches will be created automatically by giving out IPAM for the
   respective nodes
 - pods: as new pods are born, allocate the logical port with dynamic
   addressing from the switch it belongs to
 - services/endpoints: as new endpoints of services are born, create/update
   the logical load balancer on all logical switches


==================
Verify its working
# ssh into the master (in this example netdev31-1) and verify that all nodes
are STATUS "Ready".
[root@netdev31-1 ~]# oc get node
NAME         STATUS    ROLES     AGE       VERSION
netdev31-1   Ready     master    5d        v1.9.1+a0ce1bc657
netdev31-2   Ready     <none>    5d        v1.9.1+a0ce1bc657
netdev31-3   Ready     <none>    5d        v1.9.1+a0ce1bc657
netdev31-4   Ready     <none>    5d        v1.9.1+a0ce1bc657
netdev31-5   Ready     <none>    5d        v1.9.1+a0ce1bc657

