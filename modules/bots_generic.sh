#!/usr/bin/env bash
# Deploy ANY Discord/Python bot from a git repo as a systemd service —
# for bots that don't ship their own install.sh.

deploy_generic_bot() {
  need_root; hr; echo -e "  ${C_PURPLE}${C_BOLD}Deploy a bot from git${C_RESET}"; hr
  local REPO NAME DEST ENTRY
  REPO=$(ask "Git repo URL"); [ -z "$REPO" ] && { warn "Cancelled."; press_enter; return; }
  NAME=$(ask "Short name for this bot (used as service name)" "$(basename "$REPO" .git)")
  DEST=$(ask "Install directory" "/opt/${NAME}")

  if [ -d "$DEST/.git" ]; then
    spin "Updating $NAME" git -C "$DEST" pull --ff-only
  else
    spin "Cloning $NAME" git clone --depth 1 "$REPO" "$DEST"
  fi

  ENTRY=$(ask "Entry point script" "bot.py")
  [ -f "$DEST/$ENTRY" ] || { warn "$ENTRY not found in $DEST — check the repo structure."; press_enter; return; }

  spin "Creating venv" python3 -m venv "$DEST/venv"
  if [ -f "$DEST/requirements.txt" ]; then
    spin "Installing requirements" "$DEST/venv/bin/pip" install -r "$DEST/requirements.txt"
  else
    warn "No requirements.txt found — skipping dependency install."
  fi

  if [ ! -f "$DEST/config.json" ] && [ ! -f "$DEST/.env" ]; then
    warn "No config.json/.env found in $DEST — set up the bot's config before starting it, per its own README."
  fi

  if confirm "Install as a systemd service (auto-restart, runs in background)?"; then
    cat > "/etc/systemd/system/${NAME}.service" <<EOF
[Unit]
Description=${NAME} bot
After=network.target

[Service]
WorkingDirectory=${DEST}
ExecStart=${DEST}/venv/bin/python ${DEST}/${ENTRY}
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
    spin "Enabling ${NAME} service" bash -c "systemctl daemon-reload && systemctl enable ${NAME}"
    if confirm "Start it now?"; then systemctl restart "${NAME}"; ok "Started — logs: journalctl -u ${NAME} -f"; fi
  fi
  hr; press_enter
}
