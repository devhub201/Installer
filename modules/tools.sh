#!/usr/bin/env bash
# Small, genuinely useful one-shot VPS admin tools.

tool_add_swap() {
  need_root
  hr
  echo -e "  ${C_PURPLE}${C_BOLD}Add Swap${C_RESET}"
  hr
  if swapon --show | grep -q .; then
    warn "Swap already active:"
    swapon --show
    confirm "Add ANOTHER swap file anyway?" || return
  fi
  local SIZE; SIZE=$(ask "Swap size in GB" "4")
  local FILE="/swapfile_axion"
  [ -f "$FILE" ] && FILE="/swapfile_axion_$(date +%s)"
  spin "Allocating ${SIZE}G swap file" fallocate -l "${SIZE}G" "$FILE"
  chmod 600 "$FILE"
  spin "Formatting as swap" mkswap "$FILE"
  spin "Enabling swap" swapon "$FILE"
  grep -q "$FILE" /etc/fstab || echo "$FILE none swap sw 0 0" >> /etc/fstab
  local SWAPPINESS; SWAPPINESS=$(ask "Swappiness (lower = host prefers RAM, less aggressive swapping)" "10")
  sysctl -w vm.swappiness="$SWAPPINESS" >/dev/null
  sed -i '/vm.swappiness/d' /etc/sysctl.conf
  echo "vm.swappiness=$SWAPPINESS" >> /etc/sysctl.conf
  hr
  ok "${SIZE}G swap active, persists on reboot via /etc/fstab."
  free -h
  hr
  press_enter
}

tool_firewall() {
  need_root
  hr
  echo -e "  ${C_PURPLE}${C_BOLD}Basic Firewall (ufw)${C_RESET}"
  hr
  spin "Installing ufw" apt-get install -y ufw
  local SSH_PORT; SSH_PORT=$(ask "SSH port to keep open" "22")
  ufw allow "$SSH_PORT"/tcp comment "SSH" >/dev/null
  if confirm "Allow HTTP (80) + HTTPS (443)?"; then
    ufw allow 80/tcp >/dev/null; ufw allow 443/tcp >/dev/null
  fi
  local EXTRA; EXTRA=$(ask "Any extra ports to open, comma-separated (blank = none)" "")
  if [ -n "$EXTRA" ]; then
    IFS=',' read -ra PORTS <<< "$EXTRA"
    for p in "${PORTS[@]}"; do ufw allow "$(echo "$p" | xargs)" >/dev/null; done
  fi
  warn "About to enable ufw with: $(ufw status numbered | grep ALLOW | tr '\n' ' ')"
  confirm "Enable the firewall now? (don't lock yourself out!)" || { warn "Cancelled — ufw not enabled."; press_enter; return; }
  ufw --force enable
  hr
  ok "Firewall active."
  ufw status verbose
  hr
  press_enter
}

tool_fail2ban() {
  need_root
  hr
  echo -e "  ${C_PURPLE}${C_BOLD}Fail2ban${C_RESET} — SSH brute-force protection"
  hr
  spin "Installing fail2ban" apt-get install -y fail2ban
  local BANTIME; BANTIME=$(ask "Ban time in minutes" "30")
  local MAXRETRY; MAXRETRY=$(ask "Max failed attempts before ban" "5")
  cat > /etc/fail2ban/jail.local <<EOF
[DEFAULT]
bantime = ${BANTIME}m
findtime = 10m
maxretry = ${MAXRETRY}

[sshd]
enabled = true
EOF
  spin "Enabling fail2ban" systemctl enable --now fail2ban
  spin "Restarting fail2ban with new rules" systemctl restart fail2ban
  hr
  ok "fail2ban active for SSH — check bans any time with: fail2ban-client status sshd"
  hr
  press_enter
}

tool_docker() {
  need_root
  hr
  echo -e "  ${C_PURPLE}${C_BOLD}Docker${C_RESET} — standalone install"
  hr
  if command -v docker >/dev/null 2>&1; then
    ok "Docker already installed: $(docker --version)"
  else
    spin "Installing Docker (get.docker.com)" bash -c "curl -fsSL https://get.docker.com | sh"
    spin "Enabling Docker" systemctl enable --now docker
  fi
  if confirm "Install docker-compose plugin too?"; then
    spin "Installing docker-compose-plugin" apt-get install -y docker-compose-plugin
  fi
  hr
  press_enter
}

tool_benchmark() {
  hr
  echo -e "  ${C_PURPLE}${C_BOLD}Quick Server Benchmark${C_RESET}"
  hr
  echo -e "  ${C_BOLD}CPU${C_RESET}"
  lscpu | grep -E 'Model name|CPU\(s\):|MHz' | sed 's/^/    /'
  echo -e "\n  ${C_BOLD}Memory${C_RESET}"
  free -h | sed 's/^/    /'
  echo -e "\n  ${C_BOLD}Disk${C_RESET}"
  df -h / | sed 's/^/    /'
  echo -e "\n  ${C_BOLD}Disk write speed (1GB, dd)${C_RESET}"
  dd if=/dev/zero of=/tmp/axion_bench_test bs=1M count=1024 oflag=direct 2>&1 | tail -1 | sed 's/^/    /'
  rm -f /tmp/axion_bench_test
  if confirm "Also run a network speed test (installs speedtest-cli)?"; then
    spin "Installing speedtest-cli" apt-get install -y speedtest-cli
    echo -e "\n  ${C_BOLD}Network${C_RESET}"
    speedtest-cli --simple 2>/dev/null | sed 's/^/    /' || warn "speedtest-cli failed (no outbound access?)"
  fi
  hr
  press_enter
}
