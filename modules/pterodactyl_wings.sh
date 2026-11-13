#!/usr/bin/env bash
# Pterodactyl Wings installer — Docker + the wings daemon, auto-configured via the
# panel's own "auto deploy" command when you have it.

install_pterodactyl_wings() {
  need_root
  detect_os
  hr
  echo -e "  ${C_PURPLE}${C_BOLD}Pterodactyl Wings${C_RESET} — game-server daemon"
  hr

  if ! command -v docker >/dev/null 2>&1; then
    spin "Installing Docker" bash -c "curl -fsSL https://get.docker.com | sh"
  else
    ok "Docker already installed"
  fi
  spin "Enabling Docker" bash -c "systemctl enable --now docker"

  mkdir -p /etc/pterodactyl
  spin "Downloading Wings binary" bash -c \
    "curl -L -o /usr/local/bin/wings 'https://github.com/pterodactyl/wings/releases/latest/download/wings_linux_$( [ "$(uname -m)" = "aarch64" ] && echo arm64 || echo amd64)' && chmod u+x /usr/local/bin/wings"

  cat > /etc/systemd/system/wings.service <<'EOF'
[Unit]
Description=Pterodactyl Wings Daemon
After=docker.service
Requires=docker.service
PartOf=docker.service

[Service]
User=root
WorkingDirectory=/etc/pterodactyl
LimitNOFILE=4096
PIDFile=/var/run/wings/daemon.pid
ExecStart=/usr/local/bin/wings
Restart=on-failure
StartLimitInterval=180
StartLimitBurst=30
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
  systemctl daemon-reload

  echo
  echo -e "  ${C_YELLOW}Config:${C_RESET} in the panel, open ${C_BOLD}Admin → Nodes → your node → Configuration${C_RESET}"
  echo -e "  and copy the one-line 'auto deploy' command it gives you (starts with: cd /etc/pterodactyl && ...)."
  if confirm "Paste it now so I configure Wings automatically?"; then
    local DEPLOY_CMD
    DEPLOY_CMD=$(ask "Paste the full auto-deploy command")
    if [ -n "$DEPLOY_CMD" ]; then
      spin "Running panel's auto-deploy command" bash -c "$DEPLOY_CMD"
    else
      warn "Nothing pasted — skipping auto-config, you'll need to add /etc/pterodactyl/config.yml by hand."
    fi
  else
    warn "Skipped — add /etc/pterodactyl/config.yml manually before starting wings."
  fi

  spin "Enabling Wings service" systemctl enable wings
  if [ -f /etc/pterodactyl/config.yml ]; then
    spin "Starting Wings" systemctl restart wings
    ok "Wings is running — check status any time with: systemctl status wings"
  else
    warn "config.yml not present yet — start Wings yourself once it's in place: systemctl start wings"
  fi

  hr
  press_enter
}
