#!/bin/bash
wget -qO - https://www.mongodb.org/static/pgp/server-4.2.asc | sudo apt-key add -
echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu xenial/mongodb-org/4.2 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-4.2.list
apt-get install -y apt-transport-https ca-certificates
apt-get update
echo "Sleep 30 sec for apt update"; sleep 30s; echo "start apt install"
apt-get install -y mongodb-org
systemctl start mongod
systemctl enable mongod
