20171208
original
20180307
update for systemd via ovn-kubernetes RPMs
---------------

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


Edit file "user_data" to add the generated public key (above) in two
places in the file.  Ansible, in  a later step will copy this to
each VM so you will be able to ssh to each VM.

Edit the desired qcow2 file name into "vmcreate.sh" file, fedora rawhide is here:
https://dl.fedoraproject.org/pub/fedora/linux/development/rawhide/CloudImages/x86_64/images/
qcow2image=<name of qcow2 file>
e.g., qcow2image=Fedora-Cloud-Base-Rawhide-20180204.n.0.x86_64.qcow2

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
If replacing an existing implementation:

Cleanup the existing setup by running vmclean.sh after setting the
correct number of VMs.

# cd ~/vmscale
# ./vmclean.sh
# systemctl restart libvirt

Also, delete old lines for the VMs from /etc/hosts.
Also edit /root/.ssh/known_hosts
and delete lines for old IP, host and fqn of the VMs.

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


Run
./get-hosts.sh >> /etc/hosts
to get the lines needed for the VMs

# cat /etc/hosts
127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4
::1         localhost localhost.localdomain localhost6 localhost6.localdomain6

192.168.122.240 netdev31-2 wsfd-netdev31.ntdv.lab.eng.bos.redhat.com-2.example.com
192.168.122.165 netdev31-3 wsfd-netdev31.ntdv.lab.eng.bos.redhat.com-3.example.com
192.168.122.234 netdev31-1 wsfd-netdev31.ntdv.lab.eng.bos.redhat.com-1.example.com
192.168.122.154 netdev31-5 wsfd-netdev31.ntdv.lab.eng.bos.redhat.com-5.example.com
192.168.122.189 netdev31-4 wsfd-netdev31.ntdv.lab.eng.bos.redhat.com-4.example.com


Run this to verify that master can ssh to all of the VMs without password.
./try-vms.sh
to try to ssh to each host and fqn. Answer "yes" when asked.

============================
Install python on each VM (this is needed by ansible)
./install-python.sh

============================
Provision each VM to be part of the cluster:

The VMs are up and the host can reach each of them so at this
point we can provision the VMs to be part of the future cluster.

hosts5run       - script to run ansible-playbook
hosts5play.yml  - the install playbook
hosts5post1.yml - the cleanup/post-processing playbook
hosts5          - the set of hosts

./hosts5run install
does the following on each VM:
- install ansible
- install packages from the various repos (beaker-fedora and fedora)
- add the 172.30.0.0/16 CIDR to the insecure registries token
- add the brew-pulp-docker01.web.prod.ext.phx2.redhat.com:8888
  and registry.ops.openshift.com registries as insecure.
- restart docker
- restart the ovn-controller
- copy /etc/hosts to each VM - gives names and IP of all nodes
- set permissions on the excutables/scripts

After this, ose is installed...

===================================
Install Openshift-Ansible

The Openshift install is done using playbooks that are found in
an Openshift development puddle.

On the host, netdev31, get the repo:
# cat > /etc/yum.repos.d/openshift_additional.repo <<'EOF'
[AtomicOpenShift-3.9-Puddle]
name=AtomicOpenShift-3.9-Puddle
baseurl=http://download.lab.bos.redhat.com/rcm-guest/puddles/RHAOS/AtomicOpenShift/3.9/latest/$basearch/os
gpgcheck=0
enabled=1

EOF

On the host, netdev31, install the following:
# dnf install \
openshift-ansible \
openshift-ansible-docs \
openshift-ansible-playbooks \
openshift-ansible-roles

============================
At this point we are ready to install Openshift.

The ose5hosts file:
This file directs the install. There are several items to consider.

The file must contain:
os_sdn_network_plugin_name='cni'

At present we have tested with 1 master and 1 etcd
The host names are the VM's `hostname`

# ./ose5run 
ose5run facts|cluster|master|node|certs|uninstall

Install Openshift from the puddle using CNI (ovn)
(The install required python3)
# ./run5ose cluster

The above fails in the console install. Work around this by
# ./run5ose master
# ./run5ose node


==================================
After OSE is installed, run this to repair the HACK and restart the daemons

# ./hosts5run post
This does the following:
- re apply the HACK
- restart the daemons
- Add iptables firewall rules for ovn ports 6641 and 6642
- Ensure GENEVE's UDP port, 6081, isn't firewalled

At this point "oc get nodes" should show all nodes in a NotReady state.

After OVN is intalled in a later step, they will report Ready.


============================
ovn is installed using 
# ./oseovn
oseovn install|installdevel|config|uninstall

install - installs the openvswitch-ovn-kubernetes RPMs 
          from the rpms in OCP or Fedora
installdevel - installs the openvswitch-ovn-kubernetes RPMs
          from local copies in vmscale/
          During development the rpms can be built from the
          ovn-kubernetes github repo.
config  - get the configuration needed to access the API server
uninstall - remove ovn components and configuration.

1) Install either rpms from OCP or Fedora or rpms locally
built from a github ovn-kubernetes clone.

2) Run config to create the /etc/openvswitch/ovn_k8s.conf file 
and /etc/sysconfig/ovn-kubernetes files and copy them to all nodes.
Openshift is configured to use ovn here as well.  This also restarts
the daemons. At this point "oc get nodes" should show all nodes in
the Ready state.
 
============================
Notes on ovn-kubernetes rpms:

There are 3 rpms built for ovn-kubernetes

openvswitch-ovn-kubernetes is installed on the master and 
all nodes.

This is installed on the master
  openvswitch-ovn-kubernetes-master
and this is installed on all all nodes.
  openvswitch-ovn-kubernetes-node

The master and node rpms contain systemd configuration files.
ovn-controller is run on all nodes.
ovn-northd is run on the master.

The openvswitch-ovn-kubernetes RPMs are available in fedora rawhide
and in the OCP puddle.

You can clone ovn-kubernetes and build the rpms there for any commit.
Copy them here (vmscale/) and use "./oseovn installdevel" to install them.

========================
Openshift is configured to use ovn with the following.
This is done in "./oseovn config".

See if api is running
# ssh netdev31-1 oc get --raw /healthz/ready
ok

# ssh netdev31-1 oc get serviceaccount
# ssh netdev31-1 oc create serviceaccount ovn

# ssh netdev31-1 oc adm policy add-cluster-role-to-user cluster-admin -z ovn
# ssh netdev31-1 oc adm policy add-scc-to-user anyuid -z ovn
# ssh netdev31-1 oc sa get-token ovn  > /etc/origin/master/ovn.token


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

