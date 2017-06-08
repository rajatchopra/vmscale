#!/bin/bash

#rm -f /tmp/output.txt

ip=$(sudo ip a s eth1 | grep 172 | tr -s " "| cut -d " " -f 3 | cut -d "/" -f 1)
#echo $ip >> /tmp/output.txt

sudo cp /openshift.local.config/node/ca.crt /etc/openvswitch/k8s-ca.crt

sudo /usr/bin/ovnkube --init-node ${ip}  --ca-cert /etc/openvswitch/k8s-ca.crt --token eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJrdWJlcm5ldGVzL3NlcnZpY2VhY2NvdW50Iiwia3ViZXJuZXRlcy5pby9zZXJ2aWNlYWNjb3VudC9uYW1lc3BhY2UiOiJkZWZhdWx0Iiwia3ViZXJuZXRlcy5pby9zZXJ2aWNlYWNjb3VudC9zZWNyZXQubmFtZSI6Im92bi10b2tlbi01N3A5eCIsImt1YmVybmV0ZXMuaW8vc2VydmljZWFjY291bnQvc2VydmljZS1hY2NvdW50Lm5hbWUiOiJvdm4iLCJrdWJlcm5ldGVzLmlvL3NlcnZpY2VhY2NvdW50L3NlcnZpY2UtYWNjb3VudC51aWQiOiIxNmYxNGNlZS00YTVmLTExZTctOWU0Yy1iOGNhM2E1ZmFlZGMiLCJzdWIiOiJzeXN0ZW06c2VydmljZWFjY291bnQ6ZGVmYXVsdDpvdm4ifQ.J1xDUmkQw2gInj5M74XF1qAuCtI2LJEmBz-qsoYITAh-bIrmbtt9UOyhM81pDAZRiyMbmtvHMkGjlp9fdrTJqmDaGjEVIPbY9NabC_ueD8IJca0M5nEknd8WVT1rVeriEXr3Cw-BQnoJKlT56iLC1hLI-yLWHQm1h26pFgLPt7yNFuo_BpHoVHOm9DHTJUeeBaEN307LWhB66XH3ruNZ11OCZkol60Nmq5xuwf3t5sGkhrY6fCplEwJSjlw4zs7MpbpLS_C_jDNZrJg7iyJGYXRVl5vauwx09tTvJ9z3ZXhmsIQP_ZJStgEJGQvTgsBSO0xfI2XQS9VjQ-GjHsPwCA --apiserver https://10.12.76.5:8443/
