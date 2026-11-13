#!/usr/bin/env bash
# CloudPanel — installed via its official installer script.
# Source: https://www.cloudpanel.io/docs/v2/getting-started/other/

install_cloudpanel() {
  need_root
  detect_os
  hr
  echo -e "  ${C_PURPLE}${C_BOLD}CloudPanel${C_RESET} — fresh install (official installer)"
  hr
  warn "CloudPanel wants a genuinely fresh server — it will take over nginx/MySQL on this box."
  confirm "This is a clean/dedicated VPS for CloudPanel?" || { warn "Cancelled."; return; }

  echo -e "  ${C_CYAN}1)${C_RESET} MariaDB 11.8 ${C_GREY}(default, recommended)${C_RESET}"
  echo -e "  ${C_CYAN}2)${C_RESET} MariaDB 12.3"
  echo -e "  ${C_CYAN}3)${C_RESET} MySQL 8.4"
  local dbc; dbc=$(ask "Choose database engine" "1")
  local DB_ENGINE="MARIADB_11.8"
  case "$dbc" in
    2) DB_ENGINE="MARIADB_12.3" ;;
    3) DB_ENGINE="MYSQL_8.4" ;;
  esac

  export DEBIAN_FRONTEND=noninteractive
  spin "Installing prerequisites" apt-get install -y curl wget sudo

  pushd /tmp >/dev/null
  spin "Downloading official CloudPanel installer" curl -fsSL https://installer.cloudpanel.io/ce/v2/install.sh -o cloudpanel-install.sh
  info "Running installer with DB_ENGINE=${DB_ENGINE} (this takes a few minutes)..."
  if DB_ENGINE="$DB_ENGINE" bash cloudpanel-install.sh; then
    ok "CloudPanel installed."
  else
    die "CloudPanel's own installer exited with an error — see output above."
  fi
  rm -f cloudpanel-install.sh
  popd >/dev/null

  local IP; IP=$(curl -fsSL -4 ifconfig.me 2>/dev/null || hostname -I | awk '{print $1}')
  hr
  echo -e "  Panel:  ${C_BOLD}https://${IP}:8443${C_RESET}  ${C_GREY}(self-signed cert, accept the warning)${C_RESET}"
  hr
  press_enter
}
