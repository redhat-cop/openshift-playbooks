# Deployment Pipeline Documentation

This site is setup to run on OpenShift Container Platform. This repo contains all of the resources required to deploy the site across two environments in two separate clusters. A Jenkinsfile is provided as the way to builld, deploy, and promote the application across environments.

This pipeline has a few dependencies outsite of this repo:

- A Ruby Jenkins Slave Image: https://github.com/etsauer/containers-quickstarts/tree/jenkins-slave-ruby/jenkins-slaves/jenkins-slave-ruby
- A Skopeo Jenkins Slave Image: https://github.com/redhat-cop/containers-quickstarts/tree/master/jenkins-slaves/jenkins-slave-image-mgmt

The following are instructions to get the application deployed.

## 1 Development/Testing Setup

First, log in to the Dev cluster instantiate the project
```
oc login <dev cluster>
cd ./openshift-playbooks
oc create -f ./projects/projects-dev.yml
```

Build the slave image
```
oc process -f https://raw.githubusercontent.com/redhat-cop/containers-quickstarts/master/jenkins-slaves/templates/jenkins-slave-image-mgmt-template.json | oc apply -f-
```

Deploy the pipeline infrastructure
```
oc process openshift//jenkins-ephemeral | oc apply -f- -n field-guides-dev
oc process -f deploy/template.yml --param-file=deploy/dev/params | oc apply -f -
```

## 2 Production Setup

Log into the Production cluster and setup the following
```
oc login <prod cluster>
oc create -f projects/projects-prod.yml
oc create serviceaccount promoter -n field-guides-prod
oc adm policy add-role-to-user edit -z promoter -n field-guides-prod
oc process -f deploy/template.yml --param-file=deploy/prod/params | oc apply -f -
```

Now, grab the token value for the service account created above and save for later
```
TOKEN=$(oc serviceaccounts get-token promoter -n field-guides-prod)
```

Might as well set some variables for some other key info:
```
# Set these to the right values
API_URL=https://master.openshift.example.com
REGISTRY_HOSTNAME=registry.apps.openshift.example.com
```

Log back into the Development Cluster, and create the production secret, passing the Clusters API URL, Registry Hostname, and the Token from above.
```
oc login <dev cluster>
oc process -f deploy/prod-credentials.yml -p API_URL=${API_URL} REGISTRY_URL=${REGISTRY_HOSTNAME} TOKEN=${TOKEN} | oc apply -f- -n field-guides-dev
```
## Deploy pipeline

```
oc process -f build/field-guides-build.yml --param-file=build/dev/params | oc apply -f-
```
