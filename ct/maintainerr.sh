#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: Mark Tolson
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/Maintainerr/Maintainerr

APP="Maintainerr"
var_tags="${var_tags:-media}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-4096}"
var_disk="${var_disk:-10}"
var_os="${var_os:-debian}"
var_version="${var_version:-13}"
var_unprivileged="${var_unprivileged:-1}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources
  if [[ ! -d /opt/maintainerr ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "maintainerr" "Maintainerr/Maintainerr"; then
    msg_info "Stopping Service"
    systemctl stop maintainerr
    msg_ok "Service stopped"

    fetch_and_deploy_gh_release "maintainerr" "Maintainerr/Maintainerr" "tarball"

    msg_info "Building ${APP} (Patience)"
    export COREPACK_ENABLE_DOWNLOAD_PROMPT=0
    cd /opt/maintainerr
    $STD corepack install
    $STD yarn install --network-timeout 99999999
    printf 'VITE_BASE_PATH=/__PATH_PREFIX__\n' >>/opt/maintainerr/apps/ui/.env
    export NODE_OPTIONS="--max-old-space-size=3072"
    $STD yarn turbo build
    cp -r /opt/maintainerr/apps/ui/dist /opt/maintainerr/apps/server/dist/ui
    find /opt/maintainerr/apps/server/dist/ui -type f -exec sed -i 's,/__PATH_PREFIX__,,g' {} \;
    $STD yarn workspaces focus --all --production
    msg_ok "Built ${APP}"

    msg_info "Starting Service"
    systemctl start maintainerr
    msg_ok "Started Service"
    msg_ok "Updated successfully!"
  fi
  exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:6246${CL}"
