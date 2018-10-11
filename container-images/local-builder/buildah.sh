#!/bin/bash


FROM="ruby:2.4.0-alpine"

CONTAINER=$(buildah from --pull-always ${FROM})
USER_UID="1001"
CHOME="/home/jekyll"

# install packages
buildah run $CONTAINER apk add --no-cache --update make gcc libc-dev python libcurl

# copy files to container
buildah copy $CONTAINER $(pwd)/root/ /

# configure environment variables
buildah config --env "HOME=${CHOME}" --env "USER_UID=${USER_UID}" $CONTAINER

# handle setup tasks in user script
buildah run $CONTAINER /bin/sh /usr/local/bin/user_setup

# clean up
buildah run $CONTAINER rm -rf /var/cache/apk

# finalize configuration
buildah config --entrypoint '["/usr/local/bin/entrypoint"]' --cmd "/usr/local/bin/run" --workingdir "${CHOME}" --user "${USER_UID}" --port 4000 $CONTAINER

# commit
buildah commit $CONTAINER redhatcop/jekyll-local-builder:buildah

# stop container when done
buildah rm $CONTAINER