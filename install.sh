#!/bin/bash

export LIVE_PATH="$( cd "$( dirname "$0" )" && pwd )"

# Init value
export DISTRO=arch
export INSTALL_BASE=true
export INSTALL_DOCKER=true
export INSTALL_OH_MY_ZSH=true
export USERNAME=${USER}

# Read variables from env file.
export $(egrep -v '^#' .env | xargs)