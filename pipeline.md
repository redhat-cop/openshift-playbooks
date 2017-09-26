# Deployment Pipeline Documentation

## Development/Testing

This pipeline depends on https://github.com/etsauer/containers-quickstarts/tree/jenkins-slave-ruby/jenkins-slaves/jenkins-slave-ruby


First, instantiate the project
```
cd ./openshift-playbooks
oc create -f ./projects/projects.yml
```

Build and push the slave image
```
oc new-build https://github.com/etsauer/containers-quickstarts.git#jenkins-slave-ruby --context-dir='jenkins-slaves/jenkins-slave-ruby' --to='jenkins-slave-ruby'
```

Deploy the pipeline
```
oc process -f https://raw.githubusercontent.com/redhat-cop/containers-quickstarts/master/jenkins-slaves/templates/jenkins-slave-image-mgmt-template.json | oc apply -f-
oc process openshift//jenkins-ephemeral | oc apply -f- -n field-guides-dev
oc process -f deploy/field-guides-deploy-template.yml --param-file=deploy/dev/params | oc apply -f -
oc process -f build/field-guides-build.yml --param-file=build/dev/params | oc apply -f-
```

## Production Setup

```
oc login https://api.pro-us-east-1.openshift.com --token=<token>
oc create -f projects/projects-prod.yml
oc create serviceaccount promoter -n field-guides-prod
oc adm policy add-role-to-user edit -z promoter -n field-guides-prod
oc serviceaccounts get-token promoter -n field-guides-prod
oc process -f deploy/field-guides-deploy-template.yml --param-file=deploy/prod/params | oc apply -f -
```
