#!/usr/bin/env bash

# Update
sudo apt update
sudo apt upgrade -y

# Locale
sudo apt install -y software-properties-common language-pack-en zip unzip
echo "LC_ALL=en_US.UTF-8" | sudo tee /etc/default/locale
sudo update-locale LANG=en_US.UTF-8

# Timezone
echo 'UTC' | sudo tee /etc/timezone
sudo dpkg-reconfigure -f noninteractive tzdata

# JS
curl -sL https://deb.nodesource.com/setup_8.x | sudo -E bash -
sudo apt install -y nodejs build-essential

sudo apt autoremove -y
