#!/usr/bin/groovy

////
// This pipeline requires the following plugins:
// Kubernetes Plugin 0.10
////

String ocpApiServer = env.OCP_API_SERVER ? "${env.OCP_API_SERVER}" : "https://openshift.default.svc.cluster.local"

node('master') {

  env.NAMESPACE = readFile('/var/run/secrets/kubernetes.io/serviceaccount/namespace').trim()
  env.TOKEN = readFile('/var/run/secrets/kubernetes.io/serviceaccount/token').trim()

  println "${env.JOB_NAME}"
  env.APP_NAME = "${env.JOB_NAME}".replaceAll(/-?pipeline-?/, '').replaceAll(/-?${env.NAMESPACE}-?/, '')
  println "${env.APP_NAME}"
  exit 0
  def projectBase = "${env.NAMESPACE}".replaceAll(/-dev/, '')
  env.STAGE1 = "${projectBase}-dev"
  env.STAGE2 = "${projectBase}-prod"

}

podTemplate(label: 'slave-ruby', cloud: 'openshift', serviceAccount: "jenkins", containers: [
  containerTemplate(name: 'jnlp', image: 'docker.io/redhatcop/jenkins-slave-ruby', privileged: false, alwaysPullImage: true, workingDir: '/tmp', args: '${computer.jnlpmac} ${computer.name}', ttyEnabled: false)
]) {

  node('slave-ruby') {

    sh"""
      oc version
      oc get is jenkins-slave-image-mgmt -o jsonpath='{ .status.dockerImageRepository }' > /tmp/jenkins-slave-image-mgmt.out;
      oc get secret prod-credentials -o jsonpath='{ .data.api }' | base64 --decode > /tmp/prod_api;
      oc get secret prod-credentials -o jsonpath='{ .data.registry }' | base64 --decode > /tmp/prod_registry
      oc get secret prod-credentials -o jsonpath='{ .data.token }' | base64 --decode > /tmp/prod_token
    """
    env.SKOPEO_SLAVE_IMAGE = readFile('/tmp/jenkins-slave-image-mgmt.out').trim()
    env.PROD_API= readFile('/tmp/prod_api').trim()
    env.PROD_REGISTRY = readFile('/tmp/prod_registry').trim()
    env.PROD_TOKEN = readFile('/tmp/prod_token').trim()

    stage('SCM Checkout') {
      checkout scm
    }

    stage('Build Code') {

      sh """
        bundle install
        gem env
        bundle exec jekyll build
      """
    }

    stage('Run Automated Tests') {
      sh """
        export LANG=en_US.UTF-8
        bundle exec htmlproofer ./_site --check-html
      """
    }

    stage('Build Image') {
      sh "oc start-build ${APP_NAME} --from-dir=./_site/ --wait --follow"
    }

    stage("Verify Deployment to ${env.STAGE1}") {

      openshift.withCluster() {
        openshift.withProject( "${env.STAGE1}" ){
          def latestDeploymentVersion = openshift.selector('dc',"${APP_NAME}").object().status.latestVersion
          def rc = openshift.selector('rc', "${APP_NAME}-${latestDeploymentVersion}")
          rc.untilEach(1){
            def rcMap = it.object()
            return (rcMap.status.replicas.equals(rcMap.status.readyReplicas))
          }
        }
      }
    }
  }
}

podTemplate(label: 'promotion-slave', cloud: 'openshift', serviceAccount: "jenkins", containers: [
  containerTemplate(name: 'jenkins-slave-image-mgmt', image: "${env.SKOPEO_SLAVE_IMAGE}", ttyEnabled: true, command: 'cat'),
  containerTemplate(name: 'jnlp', image: 'jenkinsci/jnlp-slave:2.62-alpine', args: '${computer.jnlpmac} ${computer.name}')
]) {

  node('promotion-slave') {

    stage("Promote To ${env.STAGE2}") {

      container('jenkins-slave-image-mgmt') {
        sh """

        imageRegistry=\$(oc get is ${env.APP_NAME} --template='{{ .status.dockerImageRepository }}' -n ${env.STAGE1} | cut -d/ -f1)

        strippedNamespace=\$(echo ${env.NAMESPACE} | cut -d/ -f1)

        echo "Promoting \${imageRegistry}/${env.STAGE1}/${env.APP_NAME} -> \${PROD_REGISTRY}/${env.STAGE2}/${env.APP_NAME}"
        skopeo --tls-verify=false copy --remove-signatures --src-creds openshift:${env.TOKEN} --dest-creds openshift:${env.PROD_TOKEN} docker://\${imageRegistry}/${env.STAGE1}/${env.APP_NAME} docker://${PROD_REGISTRY}/${env.STAGE2}/${env.APP_NAME}
        """
      }
    }
  }
}
println "Application ${env.APP_NAME} is now in Production!"
