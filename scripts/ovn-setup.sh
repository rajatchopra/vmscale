#!/bin/bash

# setup to run ovn on the cluster
# gather cluster information needed to configure ovn

health=$(oc get --raw /healthz/ready)
if [ $health != 'ok' ]
then
  echo " cluster not ready"
  exit 1
fi

svcacct=$(oc get serviceaccount | grep ovn)
if [ $? -ne 0 ]
then
  oc create serviceaccount ovn
  oc adm policy add-cluster-role-to-user cluster-admin -z ovn
  oc adm policy add-scc-to-user anyuid -z ovn
  oc sa get-token ovn  > /etc/origin/master/ovn.token
fi

# build the ovn.master file

