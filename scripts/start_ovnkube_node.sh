#!/bin/bash

#rm -f /tmp/output.txt

ip=$(sudo ip a s eth1 | grep 172 | tr -s " "| cut -d " " -f 3 | cut -d "/" -f 1)
#echo $ip >> /tmp/output.txt

sudo cp /openshift.local.config/node/ca.crt /etc/openvswitch/k8s-ca.crt

sudo /usr/bin/ovnkube --init-node ${ip}  --ca-cert /etc/openvswitch/k8s-ca.crt --token eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJrdWJlcm5ldGVzL3NlcnZpY2VhY2NvdW50Iiwia3ViZXJuZXRlcy5pby9zZXJ2aWNlYWNjb3VudC9uYW1lc3BhY2UiOiJkZWZhdWx0Iiwia3ViZXJuZXRlcy5pby9zZXJ2aWNlYWNjb3VudC9zZWNyZXQubmFtZSI6Im92bi10b2tlbi1najMwcyIsImt1YmVybmV0ZXMuaW8vc2VydmljZWFjY291bnQvc2VydmljZS1hY2NvdW50Lm5hbWUiOiJvdm4iLCJrdWJlcm5ldGVzLmlvL3NlcnZpY2VhY2NvdW50L3NlcnZpY2UtYWNjb3VudC51aWQiOiI5NzYwNjQyNC00ZDc3LTExZTctYmQ3Zi1iOGNhM2E1ZmFlZGMiLCJzdWIiOiJzeXN0ZW06c2VydmljZWFjY291bnQ6ZGVmYXVsdDpvdm4ifQ.RbVZrJ6NipbcehI2Y0KjjFf1WJ1TpupSfMOyR4NC31E0c8SGB_WlGKirYbpNBt2X0YG1YjKvnJMaWj--pFqcIcdhhNEDWOSZRIq1w-_EPyB4hPGUzSZw4-btcCbvHx7c9ozzgT1WipCpA3fSEBnxUBgM0iZy38WNvu88DdEfilY-5MtdIdzgWMtWIXysL_fJImgInR9ZtfOI__7YsCmod0Mc3fF-kk_loYlBOidlr58HVfeBVjss1WNOUA9T1-E-CApXnmTYuHdOGC6r-B28jCavWMQJh_WM2eEsWp-XTG2TfsIon_SE5TiZNVYL28BZz9_-PdZf23mYNv9DytFTeA --apiserver https://10.12.76.5:8443/
