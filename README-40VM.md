20171201

Install 40VM cluster on 8 physical (beaker) hosts
Hosts are Dell R730 with 4 port NIC card, 1Tb disks.

The hosts and VMs are provisioned with Fedora-27 Server
Fedora-27 was selected bacause it includes ovs/ovn 2.8 which
is required.

THE 8 PHYSIVAL HOSTS:

The phical hosts are from a pool of hosts on beaker:
wsfd-netdev72.ntdv.lab.eng.bos.redhat.com  - primary - master for install
wsfd-netdev73.ntdv.lab.eng.bos.redhat.com
wsfd-netdev74.ntdv.lab.eng.bos.redhat.com
wsfd-netdev75.ntdv.lab.eng.bos.redhat.com
wsfd-netdev76.ntdv.lab.eng.bos.redhat.com
wsfd-netdev77.ntdv.lab.eng.bos.redhat.com
wsfd-netdev78.ntdv.lab.eng.bos.redhat.com
wsfd-netdev79.ntdv.lab.eng.bos.redhat.com

Beaker is used to provision the physical hosts with Fedora-27 Server
Beaker allocates a very small "/" partition wihch doesn't support the
needed VMs. So part of the install is to make a larger /home

The 8 hosts are setup using a combination of ansible scripts and manual
configuration. This can be made more automated in teh future.

===================================
Install and configure the 8 hosts:

Beaker is used to provision the 8 hosts.
https://beaker.engineering.redhat.com/
login:
Under the hello, ... tab, My Systems shows a list of your systems
Click on each of the 8 hosts in turn and reserve it.
Click provision:
Select Family Fedora-27
select Distro Tree Fedora-27-20171110.n.1 Server x86_64
Click Provision

When this is done each of the hosts will be running Fedora-27
Your default ssh key will be installed on each host and the 
default root password will be installed.

===================================
Provisioning the master:

I selected one host, netdev72, to be the master for installing the 
cluster and the master for the installed cluster.

As a convenience I edited /etc/hosts with shorter names:
10.254.1.1 netdev72
10.254.1.73 netdev73
10.254.1.74 netdev74
...

Install ansible:
# pip3 install ansible
or
# dnf install ansible

Create a ssh key pair:
# ssh-keygen
Use ssh-copy-id to copy the key to each of the hosts. ssh login to
each of the hosts to make sure it works without passwords or prompts.

Clone vmscale
(vmscale will be cloned on each host by ansible in a later step.)

# git clone https://github.com/rajatchopra/vmscale on the master.
# cd  vmscale
Edit file user_data to add the generated public key (above) in two
places in the file.  Ansible, in  a later step will copy this to
each host so you will be able to ssh to each VM.

Edit the desired qcow2 file name, e.g, Fedora-Cloud-Base-27-1.6.x86_64.qcow2
into vmcreate.sh

Also, change NUM_VMS_PER_MACHINE to the number of nodes/host
e.g., NUM_VMS_PER_MACHINE=${NUM_VMS_PER_MACHINE:-5}
in both vmcreate.sh and vmclean.sh

wget the qcow image:
# wget https://pubmirror2.math.uh.edu/fedora-buffet/fedora/linux/releases/27/CloudImages/x86_64/images/Fedora-Cloud-Base-27-1.6.x86_64.qcow2
This file is copied to each host as an install optimization that
saves the time needed to wget on each host.

The ansible playbook, hosts8play.yml, in a later step, copies these
files onto each host.


===================================
Manual install on each host:

Fedora server provisions a very small (15Gb). The following expands it
to 315Gb which is enough to support the VMs. When the host runs out of 
disk space the VMs pause until more space is available.
# lvextend --size +300G /dev/mapper/fedora-root ; xfs_growfs /

Ansible requires python on the remote hosts. This is not installed
as part of Fedora-27 Server.

On each host:
# dnf install -y python

NOTE:
ANSIBLE:
Ansible is used to install things on each host in the cluster.
When the hosts are configured, Ansible is used to bring up the VMs 
on each of the hosts.

When the VMs are provisioned into a L2 segment, Ansible is used to 
provision the VMs.
END NOTE:

====================
Provisioning the 8 hosts:

Ansible is used to apply changes to all 8 hosts.
hosts8run - script to run ansible-playbook
hosts8play.yml - the playbook
hosts8 - the set of hosts

hosts8play.yml does the following on each host:
- clones https://github.com/rajatchopra/vmscale
- copies the modified user_data, vmclean.sh, and vmcreate.sh
- makes the vm storage directory: /data/src/vmscale/libvirt_storage
- copies the FEdora-Cloud-Base-27-1.6.x86_64.qcow2
- installs virtulation

Run the ansible playbook:
The convenience script runs playbook hosts8play.yml using the hosts8
invantory file. You must be able to ssh without password or prompt 
to each host mentioned the hosts8 file.
# ./hosts8run

========================
Manual configuration:
Set up the internal network:
The selected hosts have 4 port NIC cards. The 10Ge port 2, eno2 is
used as the internal cluster network. The network is statically 
provisioned with the IP referencing the host, netdev72 is 10.254.254.72

Here is an example of netdev72 setup:
# cat /etc/sysconfig/network-scripts/ifcfg-eno2
TYPE=Ethernet
PROXY_METHOD=none
BROWSER_ONLY=no
BOOTPROTO="none"
IPADDR=10.254.254.72
NETMASK=255.255.0.0
DEFROUTE=yes
IPV4_FAILURE_FATAL=no
IPV6INIT=yes
IPV6_AUTOCONF=yes
IPV6_DEFROUTE=yes
IPV6_FAILURE_FATAL=no
IPV6_ADDR_GEN_MODE=stable-privacy
NAME=eno2
UUID=9c859f04-1b51-384b-a996-022754714cc3
ONBOOT=yes
AUTOCONNECT_PRIORITY=-999
DEVICE=eno2

Create a bridge:
# brctl addbr rcbr0

Edit for correct IP address
/etc/sysconfig/network-scripts/ifcfg-rcbr0
DEVICE="rcbr0"
ONBOOT="yes"
TYPE="Bridge"
BOOTPROTO="none"
IPADDR="10.254.1.79"   <<--- 79 is the host number, use 10.254.1.1 on netdev72
NETMASK="255.255.0.0"
IPV6INIT="yes"
IPV6_AUTOCONF="yes"
DHCPV6C="no"
STP="on"
DELAY="0"

Bring up the bridge
# ifup rcbr0
# ip a s rcbr0

Attach the hw nic (eno2) to the bridge
# brctl addif  rcbr0 eno2


The cluster, in a later step, will install and run on the 10.254/16
network.

On each host enable and start libvirtd

# systemctl start libvirtd
# systemctl enable libvirtd

Install ansible:
# pip3 install ansible
or
# dnf install ansible

==================
Install the 40 VMs that will be the nodes:

On each host run vmcreate.sh to create the 5 VMs

# cd vmscale
# vmcreate.sh

Manually configure the network on each of the 5 VMs on each host
to add a new interface, eth1 with the IP in the 10.254.0.0/16 nework


Manual configuration:
ssh to each host in turn.

Find the IP addresses:
# virsh net-dhcp-leases default
ssh to each address and note the VM name
Add a line to /etc/hosts
echo 192.168.122.242 netdev73-4 >> /etc/hosts
This allows easy future access by name:
# ssh netdev73-4

Create a now interface on the VM as follows:
In the below netdev72-1 is the VM name from above:
# virsh attach-interface --domain netdev72-1 --type bridge --source rcbr0 --config --live

ssh to each VM on the host in turn and add the ifcfg-eth1 file:
# cat /etc/sysconfig/network-scripts/ifcfg-eth1
# Created by cloud-init on instance boot automatically, do not edit.
#
BOOTPROTO="none"
IPADDR=10.254.72.1   <<--- 72 is the host number and 1 is the VM number on the host
NETMASK=255.255.0.0
DEVICE=eth1
ONBOOT=yes
TYPE=Ethernet
USERCTL=no

Then
# ifup eth1
# ping 10.254.1.1  <<<---- the VM can get to netdev72

==========================
Edit /etc/hosts on the master (netdev72) with the name of each VM
on the 10.254.0.0/16 net

10.254.72.1 netdev72-1a netdev72-1.example.com
10.254.72.2 netdev72-2a netdev72-2.example.com
10.254.72.3 netdev72-3a netdev72-3.example.com
...

Verify that master can ssh to all of the VMs without password. E.g.,
# ssh netdev72-2a

The cluster will be the 40 VMs that you just verified.

============================
On master:
ovn-kubernets is not currently available in a RPM.

Install golang 1.8.3 (1.9.x does not work)

Clone it and build it:
# git clone https://github.com/openvswitch/ovn-kubernetes
# cd ovn-kubernetes/go-controller
# make

The following playbook copies files from the built clone.

============================
Provision each VM to be part of the cluster:

The VMs are up and the master can reach each of them so at this
point we can provision the VMs to be part of the future cluster.


hosts40run - script to run ansible-playbook
hosts40play.yml - the playbook
hosts40 - the set of hosts

hosts40play.yml does the following on each VM:
- install ansible
- install packages from the various repos (beaker-fedora and fedora)
- add the 172.30.0.0/16 CIDR to the insecure registries token
- add the brew-pulp-docker01.web.prod.ext.phx2.redhat.com:8888 
  and registry.ops.openshift.com registries as insecure.
- restart docker
- restart the ovn-controller
- copy ovn_k8s.conf.j2 to /etc/openvswitch/ovn_k8s.conf
- copy the ovn-kubernetes files to the VMs
- copy /etc/hosts to each VM - gives names and IP of all nodes
- set permissions on the excutables/scripts
- Add iptables firewall ruls for ovn ports 6641 and 6642
- Ensure GENEVE's UDP port, 6081, isn't firewalled

At this point we are ready to install Openshift. It won't start
properly until ovnkube is run configuring Openshift to ovn.

===================================
Install Openshift

The Openshift install is done using playbooks that are found in 
an Openshift development puddle.

Get the repo:
# cat > /etc/yum.repos.d/openshift_additional.repo < EOF
[AtomicOpenShift-3.7-Puddle]
name=AtomicOpenShift-3.7-Puddle
baseurl=http://download.lab.bos.redhat.com/rcm-guest/puddles/RHAOS/AtomicOpenShift/3.7/2017-11-20.1/$basearch/os
gpgcheck=0
enabled=1

EOF

# dnf install \
openshift-ansible \
openshift-ansible-lookup-plugins \
openshift-ansible-docs \
openshift-ansible-filter-plugins \
openshift-ansible-callback-plugins \
openshift-ansible-playbooks \
openshift-ansible-roles

The osehosts file:
This file directs the install. There are several items to consider.

At present we have tested with 1 master and 1 etcd

os_sdn_network_plugin_name='cni'


Install Openshift from the puddle using CNI (ovn)
(The install required python3)
./runose


========================
When master and etcd are up:
This is taken from images/dind/
master/ovn-kubernetes-master-setup.sh
# ssh netdev72-1a
See if api is running
# oc get --raw /healthz/ready
ok
# oc get serviceaccount
# oc create serviceaccount ovn

# oc adm policy add-cluster-role-to-user cluster-admin -z ovn
# oc adm policy add-scc-to-user anyuid -z ovn
# oc sa get-token ovn  > /etc/origin/master/ovn.token

The ovn.token is used with the node startup on each node.




Initialize the master and run the main controller

```
ovnkube --init-master <master-host-name> \
        --ca-cert <path to the cacert file> \
        --token <token string for authentication with kube apiserver> \
        --apiserver <url to the kube apiserver e.g. https://10.11.12.13.8443> \
        --cluster-subnet <cidr representing the global pod network e.g. 192.168.0.0/16> \
        --net-controller
```

With the above the master ovnkube controller will initialize the central
master logical router and establish the watcher loops for the following:
 - nodes: as new nodes are born and init-node is called, the logical
   switches will be created automatically by giving out IPAM for the
   respective nodes
 - pods: as new pods are born, allocate the logical port with dynamic
   addressing from the switch it belongs to
 - services/endpoints: as new endpoints of services are born, create/update
   the logical load balancer on all logical switches

Initialize a newly added node for the OVN network

```
ovnkube --init-node <name of the node as identified in kubernetes> \
        --ca-cert <path to the cacert file> \
        --token <token string for authentication with kube apiserver> \
        --apiserver <url to the kube apiserver e.g. https://10.11.12.13.8443>
```


Verify its working
# ssh into the master netdev72-1
# oc get nodes
there should be 40 "ready" nodes.
