#!/bin/bash

set -x

env

echo "Travis Repo Slug: $TRAVIS_REPO_SLUG"
echo "Travis Branch: $TRAVIS_BRANCH"
echo "Travis Pull Request $TRAVIS_PULL_REQUEST"

# Deploy site if on master branch and not PR
if [ "$TRAVIS_REPO_SLUG" == "redhat-cop/openshift-playbooks" ] && [ "$TRAVIS_BRANCH" == "master" ] && [ "$TRAVIS_PULL_REQUEST" == false ]; then

#    openssl aes-256-cbc -K $encrypted_4ffc634c0a1c_key -iv $encrypted_4ffc634c0a1c_iv -in .travis_id_rsa.enc -out deploy_key.pem -d
     echo "Would Deploy to 
#    eval "$(ssh-agent -s)"
#    cp -f deploy_key.pem ~/.ssh/id_rsa
#    chmod 600 ~/.ssh/id_rsa
#    ssh-add ~/.ssh/id_rsa
#    ssh-keyscan $git_host >> ~/.ssh/known_hosts
#    cd _site/
#    git init
#   git config --global push.default simple
#    git add .
#    git -c "user.name=Travis" -c "user.email=noreply@redhat.com" commit -m "Deploy for ${TRAVIS_COMMIT}"
#    git remote add deploy $git_repo
#    git push --force --set-upstream deploy master
else
    echo "Skipping deployment. Not on master branch"
fi
