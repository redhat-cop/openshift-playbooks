#!/usr/bin/groovy

////
// This pipeline requires the following plugins:
// Kubernetes Plugin 0.10
////

String ocpApiServer = env.OCP_API_SERVER ? "${env.OCP_API_SERVER}" : "https://openshift.default.svc.cluster.local"

node('master') {

  env.NAMESPACE = readFile('/var/run/secrets/kubernetes.io/serviceaccount/namespace').trim()
  env.TOKEN = readFile('/var/run/secrets/kubernetes.io/serviceaccount/token').trim()
  env.OC_CMD = "oc --token=${env.TOKEN} --server=${ocpApiServer} --certificate-authority=/run/secrets/kubernetes.io/serviceaccount/ca.crt --namespace=${env.NAMESPACE}"

  env.APP_NAME = "${env.JOB_NAME}".replaceAll(/-?pipeline-?/, '').replaceAll(/-?${env.NAMESPACE}-?/, '')
  def projectBase = "${env.NAMESPACE}".replaceAll(/-dev/, '')
  env.STAGE1 = "${projectBase}-dev"
  env.STAGE2 = "${projectBase}-prod"

  sh(returnStdout: true, script: "${env.OC_CMD} get is jenkins-slave-image-mgmt --template=\'{{ .status.dockerImageRepository }}\' > /tmp/jenkins-slave-image-mgmt.out")
  env.SKOPEO_SLAVE_IMAGE = readFile('/tmp/jenkins-slave-image-mgmt.out').trim()
  println "${env.SKOPEO_SLAVE_IMAGE}"

  env.PROD_API="https://api.pro-us-east-1.openshift.com"
  env.PROD_REGISTRY="registry.pro-us-east-1.openshift.com"
  env.PROD_TOKEN="eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJrdWJlcm5ldGVzL3NlcnZpY2VhY2NvdW50Iiwia3ViZXJuZXRlcy5pby9zZXJ2aWNlYWNjb3VudC9uYW1lc3BhY2UiOiJmaWVsZC1ndWlkZXMtcHJvZCIsImt1YmVybmV0ZXMuaW8vc2VydmljZWFjY291bnQvc2VjcmV0Lm5hbWUiOiJwcm9tb3Rlci10b2tlbi0wbjU0MyIsImt1YmVybmV0ZXMuaW8vc2VydmljZWFjY291bnQvc2VydmljZS1hY2NvdW50Lm5hbWUiOiJwcm9tb3RlciIsImt1YmVybmV0ZXMuaW8vc2VydmljZWFjY291bnQvc2VydmljZS1hY2NvdW50LnVpZCI6IjdlMzM3YTMwLWEyNTgtMTFlNy05ODcwLTEyNWIwMzRkMmY0NiIsInN1YiI6InN5c3RlbTpzZXJ2aWNlYWNjb3VudDpmaWVsZC1ndWlkZXMtcHJvZDpwcm9tb3RlciJ9.aCZEKDG_N5TAAJzUOaHlpzXJbSuFwi2n20ZCv1S52CkQ5xOUceDMa5qyoVSYjq63K7uy85XwQU3N6gZzKHN0JvnTrC2K36-qs1JkMFirnAVSzGVOOm2mNIls9wcnmeiUUNXNTaiQ5l1bN2NMH9Viav4NsHL6DjRLWPSb5LTKBPcKGsqCWZZd0ta-vqyBdDEVbPCH1OHcUFmIKGE1uq08y5GTSyZsnEsoAUVksOBlQD0sOoIWOVLxbBzhe5BieCNy1-6wBytxA4Dew7iokJAuucmKq9Gg9aPW-saiQaNoGzcv8S3WIpOcvulO1w3QVLVoreFRoO_D2NUwzcEb_XJv2A"
}

podTemplate(label: 'slave-ruby', cloud: 'openshift', serviceAccount: "jenkins", containers: [
  containerTemplate(name: 'jnlp', image: 'docker-registry.default.svc:5000/field-guides-dev/jenkins-slave-ruby', privileged: false, alwaysPullImage: false, workingDir: '/tmp', args: '${computer.jnlpmac} ${computer.name}', ttyEnabled: false)
]) {

  node('slave-ruby') {

    stage('SCM Checkout') {
      checkout([
              $class: 'GitSCM', branches: [[name: '*/copedia']],
              userRemoteConfigs: [[url: 'https://github.com/etsauer/openshift-playbooks.git' ]]
      ])
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

    stage('Build Image') {
      sh "oc start-build site --from-dir=./_site/ --wait --follow"
    }

    stage("Verify Deployment to ${env.STAGE1}") {

      openshiftVerifyDeployment(deploymentConfig: "${env.APP_NAME}", namespace: "${STAGE1}", verifyReplicaCount: true)

    }
  }
}

podTemplate(label: 'promotion-slave', cloud: 'openshift', containers: [
  containerTemplate(name: 'jenkins-slave-image-mgmt', image: "${env.SKOPEO_SLAVE_IMAGE}", ttyEnabled: true, command: 'cat'),
  containerTemplate(name: 'jnlp', image: 'jenkinsci/jnlp-slave:2.62-alpine', args: '${computer.jnlpmac} ${computer.name}')
]) {

  node('promotion-slave') {

    stage("Promote To ${env.STAGE3}") {

      container('jenkins-slave-image-mgmt') {
        sh """

        set +x
        imageRegistry=\$(${env.OC_CMD} get is ${env.APP_NAME} --template='{{ .status.dockerImageRepository }}' -n ${env.STAGE1} | cut -d/ -f1)

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
