#!/usr/bin/groovy

////
// This pipeline requires the following plugins:
// Kubernetes Plugin 0.10
////

String ocpApiServer = env.OCP_API_SERVER ? "${env.OCP_API_SERVER}" : "https://openshift.default.svc.cluster.local"

node('master') {

  env.NAMESPACE = readFile('/var/run/secrets/kubernetes.io/serviceaccount/namespace').trim()
  env.TOKEN = readFile('/var/run/secrets/kubernetes.io/serviceaccount/token').trim()

  env.APP_NAME = "${env.JOB_NAME}".replaceAll(/-?pipeline-?/, '').replaceAll(/-?${env.NAMESPACE}-?/, '')
  def projectBase = "${env.NAMESPACE}".replaceAll(/-dev/, '')
  env.STAGE1 = "${projectBase}-dev"
  env.STAGE2 = "${projectBase}-prod"

}

podTemplate(label: 'slave-ruby', cloud: 'openshift', serviceAccount: "jenkins", containers: [
  containerTemplate(name: 'jnlp', image: 'docker.io/redhatcop/jenkins-slave-ruby', privileged: false, alwaysPullImage: false, workingDir: '/tmp', args: '${computer.jnlpmac} ${computer.name}', ttyEnabled: false)
]) {

  node('slave-ruby') {

    sh"""
      oc version
      oc get is jenkins-slave-image-mgmt -o jsonpath='{ .status.dockerImageRepository }' | tee /tmp/jenkins-slave-image-mgmt.out;
      oc get secret prod-credentials -o jsonpath='{ .data.api }' | base64 --decode | tee /tmp/prod_api;
      oc get secret prod-credentials -o jsonpath='{ .data.registry }' | base64 --decode | tee /tmp/prod_registry
      oc get secret prod-credentials -o jsonpath='{ .data.token }' | base64 --decode | tee /tmp/prod_token
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
        pwd
        env
        bundle install
        gem env
        bundle exec jekyll build
        ls .
      """
    }

    stage('Run Automated Tests') {
      sh """
        export LANG=en_US.UTF-8
        bundle exec htmlproofer ./_site --check-html
      """
    }

    stage('Build Image') {
      sh "oc start-build site --from-dir=./_site/ --wait --follow"
    }

    stage("Verify Deployment to ${env.STAGE1}") {

      openshiftVerifyDeployment(deploymentConfig: "${env.APP_NAME}", namespace: "${STAGE1}", verifyReplicaCount: true)

    }
  }
}

podTemplate(label: 'promotion-slave', cloud: 'openshift', serviceAccount: "jenkins", containers: [
  containerTemplate(name: 'jnlp', image: "${env.SKOPEO_SLAVE_IMAGE}", privileged: false, alwaysPullImage: false, workingDir: '/tmp', args: '${computer.jnlpmac} ${computer.name}', ttyEnabled: false)
]) {

  node('promotion-slave') {

    stage("Promote To ${env.STAGE2}") {

      container('jenkins-slave-image-mgmt') {
        sh """

        set +x
        imageRegistry=\$(oc get is ${env.APP_NAME} --template='{{ .status.dockerImageRepository }}' -n ${env.STAGE1} | cut -d/ -f1)

        strippedNamespace=\$(echo ${env.NAMESPACE} | cut -d/ -f1)

        echo "Promoting \${imageRegistry}/${env.STAGE1}/${env.APP_NAME} -> \${PROD_REGISTRY}/${env.STAGE2}/${env.APP_NAME}"
        skopeo --tls-verify=false copy --remove-signatures --src-creds openshift:${env.TOKEN} --dest-creds openshift:${env.PROD_TOKEN} docker://\${imageRegistry}/${env.STAGE1}/${env.APP_NAME} docker://${PROD_REGISTRY}/${env.STAGE2}/${env.APP_NAME}
        """
      }
    }

//              stage("Verify Deployment to ${env.STAGE3}") {

//                openshiftVerifyDeployment(deploymentConfig: "${env.APP_NAME}", apiURL: "${PROD_API}", authToken: "${PROD_TOKEN}", namespace: "${STAGE2}", verifyReplicaCount: true)

//              }

  }
}
println "Application ${env.APP_NAME} is now in Production!"
