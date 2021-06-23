#!/bin/bash

apt update
echo "Sleep 30 sec for apt update"; sleep 30s; echo "start apt install"
apt install -y ruby-full ruby-bundler build-essential
