# Deployment Pipeline Documentation

This site is setup to run on OpenShift Container Platform. This repo contains all of the resources required to deploy the site across two environments in two separate clusters. A Jenkinsfile is provided as the way to builld, deploy, and promote the application across environments.

This pipeline has a few dependencies outsite of this repo:

- A Ruby Jenkins Slave Image: https://github.com/etsauer/containers-quickstarts/tree/jenkins-slave-ruby/jenkins-slaves/jenkins-slave-ruby
- A Skopeo Jenkins Slave Image: https://github.com/redhat-cop/containers-quickstarts/tree/master/jenkins-slaves/jenkins-slave-image-mgmt
- [OpenShift-Applier](https://github.com/redhat-cop/openshift-applier) - used to deploy the CI/CD infrastructure and pipeline jobs for deploying the website.

The following are instructions to get the application deployed.

## 1 Initial Environment Setup
First, clone *this* repository into a directory such as `~/src/`
```
cd ~/src/
git clone https://github.com/redhat-cop/openshift-playbooks.git
```

Run `ansible-galaxy` to pull in the necessary requirements for the provisioning of openshift-playbooks:

- **NOTE:**  *The target directory ( `galaxy` ) is important as the playbooks know to source roles and playbooks from that location.*

```
cd ~/src/openshift-playbooks
ansible-galaxy install -r openshift-playbooks-requirements.yml -p galaxy
```

- **Note:**  *If using macOS High Sierra you may need to `export OBJC_DISABLE_INITIALIZE_FORK_SAFETY=YES` as an environment variable if using Ansible > 2.3+, as described in this [Ansible issue](https://github.com/ansible/ansible/issues/32499).*

## 2 Development/Testing Setup

Next, log in to the Dev cluster and run the dev inventory to set up the dev environment.
```
oc login <dev cluster>
cd ./openshift-playbooks
ansible-playbook -i inventory-dev/ ~/src/openshift-playbooks/galaxy/openshift-applier/playbooks/openshift-cluster-seed.yml --connection=local
```

## 3 Production Setup

Log into the Production cluster and run the production setup inventory.
```
oc login <prod cluster>
ansible-playbook -i inventory-prod/ ~/src/openshift-playbooks/galaxy/openshift-applier/playbooks/openshift-cluster-seed.yml --connection=local
```

## 4 Create the Promoter Secret

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
