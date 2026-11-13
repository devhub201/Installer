#!/usr/bin/env bash
# PufferPanel — installed via its official apt repo (packagecloud).
# Source: https://docs.pufferpanel.com/en/3.x/installing.html

install_pufferpanel() {
  need_root
  detect_os
  hr
  echo -e "  ${C_PURPLE}${C_BOLD}PufferPanel${C_RESET} — fresh install (official apt repo)"
  hr
  if [ "$OS_ID" = "ubuntu" ] && [ "$OS_VER" -lt 22 ]; then
    die "PufferPanel supports Ubuntu 22.04+ only (you're on $OS_VER)."
  fi

  export DEBIAN_FRONTEND=noninteractive
  spin "Installing prerequisites" apt-get install -y curl gnupg apt-transport-https
  mkdir -p /etc/apt/keyrings
  spin "Adding PufferPanel apt key" bash -c \
    "curl -fsSL https://packagecloud.io/pufferpanel/pufferpanel/gpgkey | gpg --dearmor -o /etc/apt/keyrings/pufferpanel.gpg"

  cat > /etc/apt/sources.list.d/pufferpanel.sources <<'EOF'
X-Repolib-Name: PufferPanel
Types: deb
URIs: https://packagecloud.io/pufferpanel/pufferpanel/any/
Suites: any
Components: main
Signed-By: /etc/apt/keyrings/pufferpanel.gpg
EOF

  spin "Refreshing package lists" apt-get update -y
  spin "Installing PufferPanel" apt-get install -y pufferpanel
  spin "Enabling PufferPanel service" systemctl enable --now pufferpanel

  local IP; IP=$(curl -fsSL -4 ifconfig.me 2>/dev/null || hostname -I | awk '{print $1}')
  hr
  ok "PufferPanel installed and running."
  echo -e "  Panel:  ${C_BOLD}https://${IP}:8080${C_RESET}  ${C_GREY}(self-signed cert by default)${C_RESET}"
  echo -e "  ${C_YELLOW}First run:${C_RESET} open that URL to create the admin account and add a node."
  hr
  press_enter
}
