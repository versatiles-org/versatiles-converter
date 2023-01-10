#!/bin/bash

set -ex

sudo apt-get -qq update
sudo apt-get -qq install -y build-essential git wget unzip tmux htop aria2 sysstat brotli cmake ifstat libsqlite3-dev
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
source "$HOME/.cargo/env"
cargo install opencloudtiles
