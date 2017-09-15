# Deployment Pipeline Documentation

## Development/Testing

This pipeline depends on https://github.com/etsauer/containers-quickstarts/tree/jenkins-slave-ruby/jenkins-slaves/jenkins-slave-ruby


First, instantiate the project
```
cd ./openshift-playbooks
oc apply -f ./projects/projects.yml
```

Build and push the slave image
```
cd ~/src
git clone https://github.com/etsauer/containers-quickstarts.git
cd containers-quickstarts
git checkout jenkins-slave-ruby
cd jenkins-slaves/jenkins-slave-ruby
docker build -t docker-registry-default.apps.d1.casl.rht-labs.com/field-guides-dev/jenkins-slave-ruby .
docker login -u $(oc whoami) -p $(oc whoami -t) docker-registry-default.apps.d1.casl.rht-labs.com
docker push docker-registry-default.apps.d1.casl.rht-labs.com/field-guides-dev/jenkins-slave-ruby
```

Deploy the pipeline
```
oc process openshift//jenkins-ephemeral | oc apply -f- -n field-guides-dev
oc process -f build/field-guides-build.yml --param-file=build/dev/params | oc apply -f-
```
