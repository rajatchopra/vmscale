#!/bin/bash

mkdir -p /data/src
cd /data/src
if [ -z vmscale ]; then
  git clone https://github.com/rajatchopra/vmscale
fi
cd vmscale
git pull
