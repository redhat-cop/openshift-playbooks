# Running Redis Cluster on OpenShift 3.1

## Overview
This repository will containerize Redis and Sentinel to run Redis Cluster on OpenShift 3. Each Pod will have two containers (Redis and Sentinel) and can be easily scaled up/down as required.

## Bill of Materials
* **Environment:** It has been built and ran on OpenShift 3.1
* **Template files:** None at this moment
* **Config files:** Individual files has been prepared and can be cloned
* **External Source Code repos:** Any application can be integrated with Redis Cluster

## Setup Instructions
Please follow the steps to build a Redis Cluster:
### 1. Cloning and preparing Dockerfile

1.1) Clone the repository:

````
    mkdir ~/redis-sentinel; cd ~/redis-sentinel/
    git clone https://github.com/shah-zobair/redis-sentinel.git
```

1.2) Prepare the Docker image:

```
    cd image/
    chmod 777 run.sh
    docker build -t redis2 .
    docker build -t redis-sentinel .
````

### 2. Push to OpenShift Registry

2.1) Push the newly created Images (redis2 and redis-sentinel to OSE Registry)

````
   oc login -u system:admin
   oc project default
   oc get service **(Note the Registry Service IP and Port)**
```

2.2) Tag the Docker images and Create new Image Streams for both images: 

```
   docker tag redis2 <Registry_IP>:<Registry_Port>/openshift/redis2
   docker tag redis-sentinel <Registry_IP>:<Registry_Port>/openshift/redis-sentinel
   oc create -f image_stream.json -n openshift
   oc create -f image_stream-sentinel.json -n openshift
````

2.3) Provide a Regular user to Build, Pull and Deploy Images into OSE Registry:
```
oadm policy add-role-to-user system:image-builder <Regular_Username> -n openshift
oadm policy add-role-to-user system:image-puller <Regular_Username> -n openshift
oadm policy add-role-to-user system:deployer <Regular_Username> -n openshift
```

2.4) Push Docker Images to registry being a regular user:
```
oc login -u <Regular_Username>
oc whoami -t **(Note the generated Token)**
docker login -u <Regular_Username> -e a@b.com -p <generated_Token> <Registry_IP>:<Registry_Port>
docker push <Registry_IP>:<Registry_Port>/openshift/redis2
docker push <Registry_IP>:<Registry_Port>/openshift/redis-sentinel
```

2.5) Verify Images in the OSE Registry:
```
oc login -u system:admin
oc get images | grep redis
```

### 3. Preparing NFS Persistent Volumes
3.1) Create two NFS directories for Redis and Sentinel Containers in the NFS Server:

```
mkdir /opt/nfs/red
chown nfsnobody.nfsnobody /opt/nfs/red
chown -R nfsnobody.nfsnobody /opt/nfs/red
chmod 775 /opt/nfs/red

mkdir /opt/nfs/redis-sentinel
chown nfsnobody.nfsnobody /opt/nfs/redis-sentinel
chown -R nfsnobody.nfsnobody /opt/nfs/redis-sentinel
chmod 775 /opt/nfs/redis-sentinel
```
3.2) Export as:

```
(In /etc/exports)
/opt/nfs/red node00-640a.oslab.opentlc.com(all_squash,rw,sync) node01-640a.oslab.opentlc.com(all_squash,rw,sync)
/opt/nfs/redis-sentinel node00-640a.oslab.opentlc.com(all_squash,rw,sync) node01-640a.oslab.opentlc.com(all_squash,rw,sync)

exportfs -a
```
### 4. Create Objetcs:

4.1) Create new project, pods, Services, Controllers for the Cluster:

```
oc new-project redis --display-name="Redis Sentinal Cluster" --description="This is the project of Redis Assignment"

oc create -f redis-master-new.yaml
oc create -f redis-sentinel-service.yaml
oc create -f redis-service.yaml
oc create -f redis-controller-new.yaml
oc create -f redis-sentinel-controller-new.yaml
oc create -f deploymentconfig-new.json
```

4.2) Create Persistent Volume for the Pods:

```
oc login -u system:admin
oc create -f volume_red.yaml
oc create -f claim_red.yaml
oc volume deploymentconfigs/redis --add --overwrite --name=myclaim2 --mount-path=/redis-master-data --source='{"nfs": { "server": "nfs00-640a", "path": "/opt/nfs/red" }}'

oc create -f volume_redis-sentinel.yaml
oc create -f claim_redis-sentinel.yaml
oc volume deploymentconfigs/redis --add --overwrite --name=myclaim3 --mount-path=/redis-sentinel-data --source='{"nfs": { "server": "nfs00-640a", "path": "/opt/nfs/redis-sentinel" }}'
```
4.3) Scale up to test:

```
oc scale rc redis --replicas=3
oc scale rc redis-sentinel --replicas=3
```

**Now applications can be connected using redis-setinel Cluster IP. (oc get service redis-sentinel)**

[Wiki Link](https://github.com/shah-zobair/redis-sentinel/wiki/Redis-Cluster-on-OpenShift-3.1)
