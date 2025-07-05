#!/bin/bash

# utils
ERROR() {
    printf "\e[101m\e[97m[ERROR]\e[49m\e[39m %s\n" "$@"
}

WARNING() {
    printf "\e[101m\e[97m[WARNING]\e[49m\e[39m %s\n" "$@"
}

INFO() {
    printf "\e[104m\e[97m[INFO]\e[49m\e[39m %s\n" "$@"
}

exists() {
    type "$1" > /dev/null 2>&1
}

# check dependencies
exists ssh-keygen || { ERROR "Please install ssh-keygen"; exit 1;}
exists perl || { ERROR "Please install perl"; exit 1;}

# generate ssh keys for control node
if [ ! -f ./secret/node.env ]; then
  INFO "Generating key pair"
  mkdir -p ./secret
  ssh-keygen -t rsa -N "" -f ./secret/id_rsa

  INFO "Generating ./secret/control.env"
  { echo "SSH_PRIVATE_KEY=$(perl -p -e "s/\n/↩/g" < ./secret/id_rsa)";
    echo "SSH_PUBLIC_KEY=$(cat ./secret/id_rsa.pub)"; } > ./secret/control.env
  
  INFO "Generating authorized_keys for nodes"
  { echo "$(cat ./secret/id_rsa.pub)"; } > ./secret/authorized_keys

  INFO "Generating ./secret/node.env"
  { echo "ROOT_PASS=root"; } > ./secret/node.env
else
  INFO "Keys already generated"
fi
