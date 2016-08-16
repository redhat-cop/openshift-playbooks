# Add a New Master Node to OSCP Cluster with embedded ETCD

## Overview
To add a new Master node with Embedded ETCD Cluster, follow the steps below:

* Take Backup of the ETCD from a working Master Node.
* Remove the faulty Master data from OSCP Cluster.
* Remove the faulty Master from ETCD Cluster.
* Prepare a Fresh VM to install OSCP packages, Docker, Disks etc.
* Run the installation playbook (byo/config.yaml) with New Master host data in the ansible host file (It will fail but install required components on new Master node).
* Remove or rename ETCD CA Certs from the New Master and from Existing Masters to generate a new set of certificate for the whole ETCD cluster.
* Rerun the installation playbook (byo/config.yaml) again.
* Stop the ETCD service from New Master Node.
* Add the New Master Node information into existing ETCD Cluster.
* Change the parameters in New Master’s /etc/etcd.conf to be part of the existing etcd cluster.
* Remove /var/lib/etcd/ contents from New Master node.
* Start the ETCD service of the New Master node.

## Detail Steps

**Assumption:** It is a 3 Master OSCP cluster. “master-01.example.com” is faulty and needs to be added again on a newly installed VM.

**Take Backup of the ETCD from a working Master Node.**
From master-02 or master-03
```
etcdctl backup --data-dir=/var/lib/etcd --backup-dir=/tmp/etcd_backup
```


**Remove the faulty Master data from OSCP Cluster.**
From master-02 or master-03
```
oc get nodes
oc delete node master-01.example.com
```


**Remove the faulty Master from ETCD Cluster.**
From master-02 or master-03
```
etcdctl -C https://master-02.example.com:2379 --ca-file=/etc/origin/master/master.etcd-ca.crt --cert-file=/etc/origin/master/master.etcd-client.crt --key-file=/etc/origin/master/master.etcd-client.key member list
etcdctl -C https://master-02.example.com:2379 --ca-file=/etc/origin/master/master.etcd-ca.crt --cert-file=/etc/origin/master/master.etcd-client.crt --key-file=/etc/origin/master/master.etcd-client.key member remove <ID>
```


**Prepare a Fresh VM to install OSCP packages, Docker, Disks etc.**
On master-01
* Subscribe the Node to openshift broker entitlement 
* Exclude/select proper docker version in /etc/yum.conf and update the node
* Prepare disks for Log, /var/lib/etcd and Docker VG
* Setup dnsmasq, copy ssh keys, install required packages and setup docker and docker storage


**Run the installation playbook (byo/config.yaml) with New Master host data in the ansible host file (It will fail but install required components on new Master node).**
From master-02 or master-03
```
ansible-playbook /usr/share/ansible/openshift-ansible/playbooks/byo/config.yml
```


**Remove or rename ETCD Client Certs from the New Master and from Existing Masters to generate a new set of certificate for the whole ETCD cluster.**
On master-01, master-02 and master-03
```
mv /etc/origin/master/master.etcd-ca.crt /etc/origin/master/master.etcd-ca.crt_original
mv /etc/origin/master/master.etcd-client.crt /etc/origin/master/master.etcd-client.crt_original
mv /etc/origin/master/master.etcd-client.csr /etc/origin/master/master.etcd-client.csr_original
mv /etc/origin/master/master.etcd-client.key /etc/origin/master/master.etcd-client.key_original

mv /etc/etcd/peer.crt /etc/etcd/peer.crt_original
mv /etc/etcd/peer.csr /etc/etcd/peer.csr_original
mv /etc/etcd/peer.key /etc/etcd/peer.key_original
```

**Rerun the installation playbook (byo/config.yaml) again.**
From master-02 or master-03
```
ansible-playbook /usr/share/ansible/openshift-ansible/playbooks/byo/config.yml
```

**Stop the ETCD service from New Master Node.**
On master-01
```
systemctl stop etcd
```

**Add the New Master Node information into existing ETCD Cluster.**
From master-02 or master-03
```
etcdctl -C https://master-02.example.com:2379 --ca-file=/etc/origin/master/master.etcd-ca.crt --cert-file=/etc/origin/master/master.etcd-client.crt --key-file=/etc/origin/master/master.etcd-client.key member add master-01.example.com https://master-01.example.com:2379
```


**Change the [cluster] parameters in New Master’s /etc/etcd/etcd.conf to be part of the existing etcd cluster. Only “ETCD_INITIAL_CLUSTER” and “ETCD_INITIAL_CLUSTER_STATE” need to be changed.**
On master-01
```
vi /etc/etcd/etcd.conf

ETCD_NAME=master-01.example.com
ETCD_LISTEN_PEER_URLS=https://172.25.141.41:2380
ETCD_DATA_DIR=/var/lib/etcd/
#ETCD_SNAPSHOT_COUNTER=10000
ETCD_HEARTBEAT_INTERVAL=500
ETCD_ELECTION_TIMEOUT=2500
ETCD_LISTEN_CLIENT_URLS=https://172.25.141.41:2379
#ETCD_MAX_SNAPSHOTS=5
#ETCD_MAX_WALS=5
#ETCD_CORS=

#[cluster]
ETCD_INITIAL_ADVERTISE_PEER_URLS=https://172.25.141.41:2380
ETCD_INITIAL_CLUSTER=master-02.example.com=https://172.25.141.42:2380,master-03.example.com=https://172.25.141.43:2380,master-01.example.com=https://172.25.141.41:2380
ETCD_INITIAL_CLUSTER_STATE=existing
ETCD_INITIAL_CLUSTER_TOKEN=etcd-cluster-1
ETCD_DISCOVERY=
#ETCD_DISCOVERY_SRV=
#ETCD_DISCOVERY_FALLBACK=proxy
#ETCD_DISCOVERY_PROXY=
ETCD_ADVERTISE_CLIENT_URLS=https://172.25.141.41:2379

#[proxy]
#ETCD_PROXY=off

#[security]
ETCD_CA_FILE=/etc/etcd/ca.crt
ETCD_CERT_FILE=/etc/etcd/server.crt
ETCD_KEY_FILE=/etc/etcd/server.key
ETCD_PEER_CA_FILE=/etc/etcd/ca.crt
ETCD_PEER_CERT_FILE=/etc/etcd/peer.crt
ETCD_PEER_KEY_FILE=/etc/etcd/peer.key
```


**Remove /var/lib/etcd/ contents from New Master node.**
On master-01
```
rm -fr /var/lib/etcd/*
```

**Start the ETCD service of the New Master node.**
On master-01
```
systemctl start etcd
```

## Testing

**Check the Cluster health**

From master-01 or master-02 or master-03
```
etcdctl -C https://master-01.example.com:2379 --ca-file=/etc/origin/master/master.etcd-ca.crt --cert-file=/etc/origin/master/master.etcd-client.crt --key-file=/etc/origin/master/master.etcd-client.key cluster-health

etcdctl -C https://master-02.example.com:2379 --ca-file=/etc/origin/master/master.etcd-ca.crt --cert-file=/etc/origin/master/master.etcd-client.crt --key-file=/etc/origin/master/master.etcd-client.key cluster-health

etcdctl -C https://master-03.example.com:2379 --ca-file=/etc/origin/master/master.etcd-ca.crt --cert-file=/etc/origin/master/master.etcd-client.crt --key-file=/etc/origin/master/master.etcd-client.key cluster-health
```

**Check the new Master is in ready state**

From master-01 or master-02 or master-03
```
oc get nodes --show-labels
```
