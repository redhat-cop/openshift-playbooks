# Deployment Pipeline Documentation

This site is setup to run on OpenShift Container Platform. This repo contains all of the resources required to deploy the site across two environments in two separate clusters. A Jenkinsfile is provided as the way to builld, deploy, and promote the application across environments.

This pipeline has a few dependencies outsite of this repo:

- A Ruby Jenkins Slave Image: https://github.com/etsauer/containers-quickstarts/tree/jenkins-slave-ruby/jenkins-slaves/jenkins-slave-ruby
- A Skopeo Jenkins Slave Image: https://github.com/redhat-cop/containers-quickstarts/tree/master/jenkins-slaves/jenkins-slave-image-mgmt

The following are instructions to get the application deployed.

## 1 Development/Testing Setup

First, log in to the Dev cluster and run the dev inventory to set up the dev environment.
```
oc login <dev cluster>
cd ./openshift-playbooks
ansible-playbook -i inventory-dev/ ../casl-ansible/playbooks/openshift-cluster-seed.yml --connection=local
```

## 2 Production Setup

Log into the Production cluster and run the production setup inventory.
```
oc login <prod cluster>
ansible-playbook -i inventory-prod/ ../casl-ansible/playbooks/openshift-cluster-seed.yml --connection=local
```

## 3 Create the Promoter Secret

As part of the ansible run above, a service account called _promoter_ gets created with the "edit" role, in order to facilitate the promotion of the site from dev to production. Grab the token value for the service account created above and save for later
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

At this point the pipeline should be fully functional and able to build, deploy, and promote the site.
