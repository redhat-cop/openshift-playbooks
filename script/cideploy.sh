#!/bin/bash


function generate_pr_statistics() {
   
    file="./_site/PR.txt"
    echo "Generating statistics for pull request..."
    echo >> $file
    echo "*** Pull Request Statistics ***" >> $file
    echo >> $file
    echo "Pull Request: ${TRAVIS_PULL_REQUEST}" >> $file
    git log ${TRAVIS_COMMIT_RANGE} -p >> $file

}


# Determine which Git configurations to use. PR's go to Test
if [ "$TRAVIS_PULL_REQUEST" == false ]; then
    git_repo=$git_repo_prod
    git_host=$git_host_prod
else
    git_repo=$git_repo_test
    git_host=$git_host_test
fi


# If Pull Request, Create Statistics
if [ "$TRAVIS_PULL_REQUEST" != "false" ]; then
    generate_pr_statistics
fi

# Deploy site if slug is rhtconsulting/openshift-playbooks or on master branch and not PR
if [ "$TRAVIS_REPO_SLUG" == "rhtconsulting/openshift-playbooks" ] && [[ "$TRAVIS_BRANCH" == "master" || "$TRAVIS_PULL_REQUEST" != "false" ]]; then
    
    # Decrypt private key
    openssl aes-256-cbc -K $encrypted_4ffc634c0a1c_key -iv $encrypted_4ffc634c0a1c_iv -in .travis_id_rsa.enc -out deploy_key.pem -d

    eval "$(ssh-agent -s)"
    cp -f deploy_key.pem ~/.ssh/id_rsa
    chmod 600 ~/.ssh/id_rsa
    ssh-add ~/.ssh/id_rsa
    ssh-keyscan $git_host >> ~/.ssh/known_hosts
    cd _site/
    git init
    git config user.name "Travis"
    git config user.emal "noreply@redhat.com"
    git add *
    git commit -m "Deploy for ${TRAVIS_COMMIT}"
    git remote add deploy $git_repo
    git push --force deploy

    #TODO: Notifications

else
    echo "Skipping deployment. Not on master branch or a pull request"
fi