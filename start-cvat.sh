#!/bin/bash

usage() {
    echo -e "\nSets up a CVAT instance with serveo.net"
    echo -e "\n\t-v|--version <CVAT version>\n\t\tDefaults to 'develop'. Specifies the branch/tag from the CVAT repository to be used in the deployemnt"
    echo -e "\n\t-s|--subdomain <submain>\n\t\tDefaults to 'my-cvat'. Specifies a subdomain to be used with serveo.net."
    echo -e "\n\t-h|--help\n\t\tShows this help message."
    echo -e "\n"
    exit 0
}

# Getting positional arguments base on 
# https://stackoverflow.com/a/14203146

CVAT_VERSION=develop
SUBDOMAIN=my-cvat
DOMAIN=serveo.net

CVAT_HOME=$HOME/cvat

while [[ $# -gt 0 ]]; do
  case $1 in
    -v|--version)
      CVAT_VERSION="$2"
      shift # past argument
      shift # past value
      ;;
    -s|--subdomain)
      SUBDOMAIN="$2"
      shift # past argument
      shift # past value
      ;;
    -h|--help)
      usage
      ;;
    -*|--*)
      echo "Unknown option $1"
      exit 1
      ;;
  esac
done

echo "CVAT_VERSION = ${CVAT_VERSION}"
echo "SUBDOMAIN = ${SUBDOMAIN}"
echo "DOMAIN = ${DOMAIN}"

install_deps() {
    sudo apt update
    sudo apt --no-install-recommends install -y \
        apt-transport-https \
        ca-certificates \
        curl \
        gnupg-agent \
        software-properties-common
}

install_docker() {
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
    sudo add-apt-repository \
        "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
        $(lsb_release -cs) \
        stable"

    sudo apt update
    sudo apt --no-install-recommends install -y \
        docker-ce docker-ce-cli containerd.io docker-compose-plugin

#    sudo groupadd docker
#    sudo usermod -aG docker $USER
}

install_cvat() {
    mkdir $CVAT_HOME
    git clone https://github.com/opencv/cvat $HOME/cvat
    cd $HOME/cvat
    git checkout $CVAT_VERSION
}

run_cvat() {
    cd $HOME/cvat
    sudo docker compose up -d
    sudo docker exec -it cvat_server bash -ic 'python3 ~/manage.py createsuperuser'
}

run_proxy() {
    ssh -R $SUBDOMAIN:80:localhost:80 serveo.net
}

export CVAT_HOST=$REMOTE
install_deps
install_docker
install_cvat
run_cvat
run_proxy

