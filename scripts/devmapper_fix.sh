#!/bin/bash

sudo systemctl stop origin-node
sudo systemctl stop docker
sudo dmsetup remove_all
sudo dmsetup -y udevcomplete_all
sudo systemctl start docker
sudo systemctl start origin-node
