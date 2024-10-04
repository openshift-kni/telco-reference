#!/bin/bash -xe

command -v microdnf
if [[ $? -eq 0 ]] ; then
    microdnf install -y python3 python3-pip
    python3 -m pip install yamllint
else
    echo "Unexpected environment, not installing yamllint"
fi

