#!/bin/bash

# Run.sh - Script to build and run a Docker container for the Jekyll site generator


SCRIPT_BASE_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
JEKYLL_DOCKER_IMAGE="rhtconsulting/jekyll-asciidoc"
SSH_DIR=~/.ssh
REMOVE_CONTAINER_ON_EXIT="--rm"
REPOSITORY=
REPOSITORY_VOLUME=""
REBUILD=


usage() {
    echo "
     Usage: $0 [options]
     Options:
     --name=<name>                 : Name of the assembled image (Default: rhtconsulting/jekyll-asciidoc)
     --keep                        : Whether to keep the the container after exiting
     --rebuild                     : Rebuilds the image if it already exists
     --directory=<directory>       : Directory containing source code to mount inside the container
     --help                        : Show Usage Output
	 "
}



# Process Input

for i in "$@"
do
  case $i in
    -c=*|--configdir=*)
      OPENSTACK_CONFIG_DIR="${i#*=}"
      shift;;
	  -k|--keep)
      REMOVE_CONTAINER_ON_EXIT=""
      shift;;
  	-n=*|--name=*)
      JEKYLL_DOCKER_IMAGE="${i#*=}"
      shift;;
    -r|--rebuild)
      REBUILD="true"
	  shift;;
  	-d=*|--directory=*)
      DIRECTORY="${i#*=}"
      shift;;
    -h|--help)
      usage;
      exit 0;
      ;;
    *)
      echo "Invalid Option: ${i#*=}"
      usage;
      exit 1;
      ;;
  esac
done

if [ -z ${DIRECTORY} ]; then
	echo "Error: Source code directory not specified"
	exit 1
fi

if [ ! -d ${DIRECTORY} ]; then
	echo "Error: Could not locate specified repository directory"
	exit 1
fi

DOCKER_IMAGES=$(docker images)

if [ $? -ne 0 ]; then
    echo "Error: Failed to determine installed docker images. Please verify connectivity to Docker socket."
    exit 1
fi

DOCKER_IMAGE=$(echo -e "${DOCKER_IMAGES}" | awk '{ print $1 }' | grep ${JEKYLL_DOCKER_IMAGE})

if [ $? -gt 1 ]; then
  echo "Error: Failed to parse the Docker images to find ${JEKYLL_DOCKER_IMAGE} image."
  exit 1
fi

# Delete Image if image exists and rebuild indicated
if [ ! -z $DOCKER_IMAGE ] && [ ! -z $REBUILD ]; then
	echo "Removing ${JEKYLL_DOCKER_IMAGE} image...."
	docker rmi -f ${JEKYLL_DOCKER_IMAGE}
	DOCKER_IMAGE=
fi


# Check if Image has been build previously
if [ -z $DOCKER_IMAGE ]; then
	echo "Building Docker Image ${OPENSTACK_CLIENT_IMAGE}...."
	docker build -t ${JEKYLL_DOCKER_IMAGE} ${SCRIPT_BASE_DIR}
fi


DIRECTORY_VOLUME="-v ${DIRECTORY}:/home/builder/source:z"

echo "Starting Jekyll Asciidoc Container...."
echo
docker run -it ${REMOVE_CONTAINER_ON_EXIT} ${DIRECTORY_VOLUME} -p 4000:4000 ${JEKYLL_DOCKER_IMAGE}
