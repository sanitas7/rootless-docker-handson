#!/bin/bash

sudo apt-get update

# インストーラのダウンロードと実行
sudo apt-get install uidmap -y
export FORCE_ROOTLESS_INSTALL=1
curl -fsSL https://get.docker.com/rootless | sh

# Daemonとクライアントの設定
systemctl --user start docker
systemctl --user enable docker
sudo loginctl enable-linger $(whoami)
export DOCKER_HOST=unix://$XDG_RUNTIME_DIR/docker.sock

# rootless contextの作成
docker context create rootless \
    --description "for rootless mode" \
    --docker "host=unix://$XDG_RUNTIME_DIR/docker.sock"

# 再起動
sudo reboot
