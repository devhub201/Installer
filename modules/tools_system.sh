#!/usr/bin/env bash
# System basics.

sys_update() { need_root; hr; spin "apt update" apt-get update -y; spin "apt upgrade" apt-get upgrade -y; hr; ok "System up to date."; press_enter; }

sys_add_user() {
  need_root; hr; echo -e "  ${C_PURPLE}${C_BOLD}Create sudo user${C_RESET}"; hr
  local U; U=$(ask "Username"); [ -z "$U" ] && { warn "Cancelled."; press_enter; return; }
  id "$U" &>/dev/null && { warn "User $U already exists."; press_enter; return; }
  spin "Creating $U" adduser --gecos "" --disabled-password "$U"
  spin "Adding to sudo group" usermod -aG sudo "$U"
  info "Set a password for $U:"; passwd "$U"
  hr; ok "User $U created with sudo access."; press_enter
}

sys_hostname() { need_root; hr; local H; H=$(ask "New hostname"); [ -z "$H" ] && return; spin "Setting hostname" hostnamectl set-hostname "$H"; hr; ok "Hostname set to $H"; press_enter; }

sys_timezone() { need_root; hr; local T; T=$(ask "Timezone (e.g. Asia/Kolkata)" "Asia/Kolkata"); spin "Setting timezone" timedatectl set-timezone "$T"; hr; ok "Timezone: $(timedatectl show -p Timezone --value)"; press_enter; }

sys_dev_basics() { need_root; hr; spin "Installing build-essential, git, curl, wget, unzip" apt-get install -y build-essential git curl wget unzip; hr; ok "Dev basics installed."; press_enter; }

sys_cli_tools() { need_root; hr; spin "Installing htop, btop, neofetch, tmux, screen" bash -c "apt-get install -y htop tmux screen neofetch || apt-get install -y htop tmux screen; (apt-get install -y btop || true)"; hr; ok "CLI tools installed."; press_enter; }

sys_cleanup() {
  need_root; hr; echo -e "  ${C_PURPLE}${C_BOLD}Disk cleanup${C_RESET}"; hr
  spin "apt autoremove" apt-get autoremove -y
  spin "apt clean" apt-get clean
  spin "Vacuuming systemd journal (keep 3 days)" journalctl --vacuum-time=3d
  command -v docker >/dev/null 2>&1 && confirm "Also prune unused Docker images/containers?" && spin "docker system prune" docker system prune -af
  hr; ok "Cleanup done."; df -h /; press_enter
}

sys_motd() {
  need_root; hr
  cat > /etc/motd <<'EOF'

   █████╗ ██╗  ██╗██╗ ██████╗ ███╗   ██╗██╗  ██╗ ██████╗ ███████╗████████╗
  ██╔══██╗╚██╗██╔╝██║██╔═══██╗████╗  ██║██║  ██║██╔═══██╗██╔════╝╚══██╔══╝
  ███████║ ╚███╔╝ ██║██║   ██║██╔██╗ ██║███████║██║   ██║███████╗   ██║
  ██╔══██║ ██╔██╗ ██║██║   ██║██║╚██╗██║██╔══██║██║   ██║╚════██║   ██║
  ██║  ██║██╔╝ ██╗██║╚██████╔╝██║ ╚████║██║  ██║╚██████╔╝███████║   ██║
  ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝ ╚═════╝ ╚═╝  ╚═══╝╚═╝  ╚═╝ ╚═════╝ ╚══════╝   ╚═╝
         Managed with The Axion Installer — unauthorized access prohibited.

EOF
  ok "Login banner set (/etc/motd)."; press_enter
}

sys_ssh_hardening() {
  need_root; hr; echo -e "  ${C_PURPLE}${C_BOLD}SSH hardening${C_RESET}"; hr
  warn "Make sure you have a working non-root sudo user + SSH key before disabling root/password login!"
  local SSHD=/etc/ssh/sshd_config
  cp "$SSHD" "${SSHD}.axion.bak"
  if confirm "Disable root SSH login?"; then sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin no/' "$SSHD"; fi
  if confirm "Disable SSH password auth (key-only)?"; then sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication no/' "$SSHD"; fi
  local PORT; PORT=$(ask "Change SSH port? (blank = keep current)" "")
  if [ -n "$PORT" ]; then sed -i "s/^#\?Port .*/Port ${PORT}/" "$SSHD"; warn "Remember: ufw allow ${PORT}/tcp before you log out, or you'll lock yourself out!"; fi
  spin "Restarting sshd" systemctl restart ssh
  hr; ok "SSH config updated (backup at ${SSHD}.axion.bak)."; press_enter
}

sys_unattended_upgrades() {
  need_root; hr
  spin "Installing unattended-upgrades" apt-get install -y unattended-upgrades
  spin "Enabling automatic security updates" dpkg-reconfigure -fnoninteractive unattended-upgrades
  hr; ok "Automatic security updates enabled."; press_enter
}
