#!/bin/bash

GOPATH=${GOPATH:-${HOME}/go}
GOBIN=${GOBIN:-${GOPATH}/bin}
MCMAKER=${MCMAKER:-${GOBIN}/mcmaker}
MCPROLE=${MCPROLE:-master}

${MCMAKER} -name 11-stalld-backend -mcp ${MCPROLE} -stdout \
        file -source stalld-backend -path /etc/sysconfig/stalld-backend -mode 0644 \
        dropin -source stalld-backend.conf -for stalld.service
