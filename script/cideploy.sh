#!/bin/bash


# Deploy site if on master branch and not PR
if [ "$TRAVIS_REPO_SLUG" == "rhtconsulting/openshift-playbooks" ] && [ "$TRAVIS_BRANCH" == "master" ] && [ "$TRAVIS_PULL_REQUEST" == false ]; then

  deploy_repo=${git_repo}
  deploy_host=${git_host}

elif [ "$TRAVIS_BRANCH" != "master" ] && [ "$TRAVIS_PULL_REQUEST" == true ]; then

  deploy_repo=${git_repo_test}
  deploy_host=${git_host_test}

fi

if [ -z ${deploy_repo} ] && [ -z $deploy_host ]; then
  openssl aes-256-cbc -K $encrypted_4ffc634c0a1c_key -iv $encrypted_4ffc634c0a1c_iv -in .travis_id_rsa.enc -out deploy_key.pem -d

  eval "$(ssh-agent -s)"
  cp -f deploy_key.pem ~/.ssh/id_rsa
  chmod 600 ~/.ssh/id_rsa
  ssh-add ~/.ssh/id_rsa
  ssh-keyscan $deploy_host >> ~/.ssh/known_hosts
  cd _site/
  git init
  git config user.name "Travis"
  git config user.emal "noreply@redhat.com"
  git add *
  git commit -m "Deploy for ${TRAVIS_COMMIT}"
  git remote add deploy $deploy_repo
  git push --force deploy
else
    echo "Skipping deployment. Criteria not met."
fi
