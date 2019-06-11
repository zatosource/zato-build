#!/bin/bash

basepath=$(dirname $(readlink -e $0))

function usage(){
    echo "$0 GITLAB_USER GITLAB_TOKEN PACKAGE_PATH DOCKER_IMAGES"
    echo ""
    echo "GITLAB_USER: GitLab user"
    echo "GITLAB_TOKEN: GitLab access token (https://gitlab.com/help/user/project/container_registry#using-with-private-projects)"
    echo "PACKAGE_PATH: local path to package to install en the Docker image"
    echo "DOCKER_IMAGES: list of names and tags to set to the generated Docker image (comma separated)"
}

if [[ "$1" == "-h" || "$1" == "--help" ]] ; then
    usage
    exit 0
fi

if [[ -z "$1" ]] ; then
    echo "Argument 1 must be the GitLab user. Can't be empty."
    usage
    exit 1
fi

if [[ -z "$2" ]] ; then
    echo "Argument 2 must be the GitLab token. Can't be empty."
    usage
    exit 1
fi

if [[ -z "$3" || ! -f "$3" ]] ; then
    echo "Argument 3 must be path to the generated package that is to be installed in the Docker image. Can't be empty."
    usage
    exit 1
fi

if [[ -z "$4" ]] ; then
    echo "list of names and tags to set to the generated Docker image (comma separated). Can't be empty."
    usage
    exit 1
fi

GITLAB_USER="${1}"
GITLAB_TOKEN="${2}"
PACKAGE_PATH="${3}"
CREATE_DOCKER_IMAGES="${4}"

echo "Build images"
package_name="$(basename ${PACKAGE_PATH})"
pushd $basepath/../docker/cloud/ || exit 1
    cp "${PACKAGE_PATH}" "${package_name}"
    sed -i -e "s|zato-3.1.0-python_amd64-bionic.deb|${package_name}|" Dockerfile

    docker login registry.gitlab.com -u "${GITLAB_USER}" -p "${GITLAB_TOKEN}"

    for image in $(echo "${CREATE_DOCKER_IMAGES}"| sed "s/,/\ /g");do
        echo "Building image $image"
        docker build -t $image .
        docker push $image
    done
popd || exit 1
