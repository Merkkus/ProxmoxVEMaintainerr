#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: Mark Tolson
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/Maintainerr/Maintainerr

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt-get install -y \
  build-essential \
  python3
msg_ok "Installed Dependencies"

NODE_VERSION="22" setup_nodejs

fetch_and_deploy_gh_release "maintainerr" "Maintainerr/Maintainerr" "tarball"

msg_info "Building Maintainerr (Patience)"
export COREPACK_ENABLE_DOWNLOAD_PROMPT=0
$STD corepack enable
cd /opt/maintainerr
$STD corepack install
$STD yarn install --network-timeout 99999999
printf 'VITE_BASE_PATH=/__PATH_PREFIX__\n' >>/opt/maintainerr/apps/ui/.env
export NODE_OPTIONS="--max-old-space-size=3072"
$STD yarn turbo build
cp -r /opt/maintainerr/apps/ui/dist /opt/maintainerr/apps/server/dist/ui
find /opt/maintainerr/apps/server/dist/ui -type f -exec sed -i 's,/__PATH_PREFIX__,,g' {} \;
$STD yarn workspaces focus --all --production
msg_ok "Built Maintainerr"

msg_info "Setting Up Data Directory"
mkdir -p /opt/data/logs
msg_ok "Set Up Data Directory"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/maintainerr.service
[Unit]
Description=Maintainerr Service
Wants=network-online.target
After=network-online.target

[Service]
Environment=NODE_ENV=production
Environment=DATA_DIR=/opt/data
Environment=UV_USE_IO_URING=0
Type=exec
Restart=on-failure
WorkingDirectory=/opt/maintainerr/apps/server
ExecStart=/usr/bin/node dist/main

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now maintainerr
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
