# Deployment Pipeline Documentation

```
oc apply -f ./projects/projects.yml
oc process openshift//jenkins-ephemeral | oc apply -f- -n field-guides-dev
```
