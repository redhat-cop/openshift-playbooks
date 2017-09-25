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
//  env.STAGE1 = "${projectBase}-dev"
//  env.STAGE2 = "${projectBase}-prod"

//  sh(returnStdout: true, script: "${env.OC_CMD} get is jenkins-slave-image-mgmt --template=\'{{ .status.dockerImageRepository }}\' -n openshift > /tmp/jenkins-slave-image-mgmt.out")
//  env.SKOPEO_SLAVE_IMAGE = readFile('/tmp/jenkins-slave-image-mgmt.out').trim()
//  println "${env.SKOPEO_SLAVE_IMAGE}"

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

      input "Promote Application to Stage?"
    }
  }
}

/*
podTemplate(label: 'promotion-slave', cloud: 'openshift', containers: [
  containerTemplate(name: 'jenkins-slave-image-mgmt', image: "${env.SKOPEO_SLAVE_IMAGE}", ttyEnabled: true, command: 'cat'),
  containerTemplate(name: 'jnlp', image: 'jenkinsci/jnlp-slave:2.62-alpine', args: '${computer.jnlpmac} ${computer.name}')
]) {

  node('promotion-slave') {

    stage("Promote To ${env.STAGE3}") {

      container('jenkins-slave-image-mgmt') {
        sh """

        set +x
        imageRegistry=\$(${env.OC_CMD} get is ${env.APP_NAME} --template='{{ .status.dockerImageRepository }}' -n ${env.STAGE2} | cut -d/ -f1)

        strippedNamespace=\$(echo ${env.NAMESPACE} | cut -d/ -f1)

        echo "Promoting \${imageRegistry}/${env.STAGE2}/${env.APP_NAME} -> \${imageRegistry}/${env.STAGE3}/${env.APP_NAME}"
        skopeo --tls-verify=false copy --remove-signatures --src-creds openshift:${env.TOKEN} --dest-creds openshift:${env.TOKEN} docker://\${imageRegistry}/${env.STAGE2}/${env.APP_NAME} docker://\${imageRegistry}/${env.STAGE3}/${env.APP_NAME}
        """
      }
    }

    stage("Verify Deployment to ${env.STAGE3}") {

      openshiftVerifyDeployment(deploymentConfig: "${env.APP_NAME}", namespace: "${STAGE3}", verifyReplicaCount: true)

    }

  }
}
*/
println "Application ${env.APP_NAME} is now in Production!"
