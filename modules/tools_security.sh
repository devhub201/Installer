#!/usr/bin/env bash
# Security tools. (tool_firewall and tool_fail2ban already live in tools.sh)

sec_clamav() {
  need_root; hr; echo -e "  ${C_PURPLE}${C_BOLD}ClamAV scan${C_RESET}"; hr
  spin "Installing ClamAV" apt-get install -y clamav clamav-daemon
  spin "Updating virus definitions" freshclam || true
  local DIR; DIR=$(ask "Directory to scan" "/home")
  info "Scanning $DIR (this can take a while)..."
  clamscan -r --bell -i "$DIR" | tee -a "$LOG_FILE"
  hr; press_enter
}

sec_rkhunter() {
  need_root; hr; echo -e "  ${C_PURPLE}${C_BOLD}rkhunter (rootkit hunter)${C_RESET}"; hr
  spin "Installing rkhunter" apt-get install -y rkhunter
  spin "Updating rkhunter data" rkhunter --update || true
  spin "Running baseline properties check" rkhunter --propupd
  info "Running a check (warnings are normal on a first run, review the log)..."
  rkhunter --check --sk | tail -40
  hr; echo -e "  Full log: /var/log/rkhunter.log"; press_enter
}
