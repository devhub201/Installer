#!/usr/bin/env bash
# Network, backup & misc.

net_tailscale() {
  need_root; hr; echo -e "  ${C_PURPLE}${C_BOLD}Tailscale${C_RESET}"; hr
  spin "Installing Tailscale (official script)" bash -c "curl -fsSL https://tailscale.com/install.sh | sh"
  info "Run 'tailscale up' and follow the login link to join this device to your tailnet."
  confirm "Run 'tailscale up' now?" && tailscale up
  hr; press_enter
}

net_vsftpd() {
  need_root; hr; echo -e "  ${C_PURPLE}${C_BOLD}vsftpd${C_RESET} — FTP server"; hr
  spin "Installing vsftpd" apt-get install -y vsftpd
  sed -i 's/^#\?write_enable=.*/write_enable=YES/' /etc/vsftpd.conf
  grep -q '^write_enable=' /etc/vsftpd.conf || echo "write_enable=YES" >> /etc/vsftpd.conf
  spin "Enabling vsftpd" systemctl enable --now vsftpd
  hr; ok "FTP server running — use existing system users to log in (or create one via System → Create sudo user)."; press_enter
}

net_rclone() {
  need_root; hr; echo -e "  ${C_PURPLE}${C_BOLD}rclone${C_RESET} — sync to/from S3, Google Drive, Backblaze, etc."; hr
  spin "Installing rclone (official script)" bash -c "curl -fsSL https://rclone.org/install.sh | bash"
  info "Run 'rclone config' to add a remote (Google Drive, S3, Backblaze B2, etc.)."
  hr; press_enter
}

net_backup_cron() {
  need_root; hr; echo -e "  ${C_PURPLE}${C_BOLD}Scheduled backup${C_RESET}"; hr
  local SRC; SRC=$(ask "Folder to back up" "/var/www")
  local DEST; DEST=$(ask "Backup destination folder" "/backups")
  local KEEP; KEEP=$(ask "Days to keep old backups" "7")
  local SCHED; SCHED=$(ask "Cron schedule" "0 3 * * *")
  mkdir -p "$DEST"
  cat > /usr/local/bin/axion-backup.sh <<EOF
#!/usr/bin/env bash
STAMP=\$(date +%Y%m%d-%H%M%S)
tar -czf "${DEST}/backup-\${STAMP}.tar.gz" -C "$(dirname "$SRC")" "$(basename "$SRC")"
find "${DEST}" -name 'backup-*.tar.gz' -mtime +${KEEP} -delete
EOF
  chmod +x /usr/local/bin/axion-backup.sh
  ( crontab -l 2>/dev/null | grep -v 'axion-backup.sh' ; echo "${SCHED} /usr/local/bin/axion-backup.sh >> /var/log/axion-backup.log 2>&1" ) | crontab -
  hr; ok "Backing up ${SRC} → ${DEST} on schedule '${SCHED}', keeping ${KEEP} days."; press_enter
}
