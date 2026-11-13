#!/usr/bin/env bash
# Installs CUBE's AxionHost Tickets AI support bot by delegating to its own installer.

install_axionhost_tickets() {
  need_root
  hr
  echo -e "  ${C_PURPLE}${C_BOLD}AxionHost Tickets${C_RESET} — AI-powered support ticket bot"
  hr
  local DEST
  DEST=$(ask "Install directory" "/opt/axionhost-tickets")

  if [ -d "$DEST/.git" ]; then
    info "Already cloned at $DEST — pulling latest instead of re-cloning."
    spin "Updating AxionHost Tickets" git -C "$DEST" pull --ff-only
  else
    spin "Cloning AxionHost Tickets" git clone --depth 1 https://github.com/devhub201/axionhost-tickets "$DEST"
  fi

  if [ -x "$DEST/install.sh" ]; then
    info "Handing off to its own installer (asks for your Discord token + OpenAI key) ..."
    warn "Reminder: enable Server Members Intent + Presence Intent for this bot in the Discord Developer Portal."
    hr
    bash "$DEST/install.sh"
  else
    die "install.sh not found/executable in $DEST — check the axionhost-tickets repo."
  fi
  hr
  press_enter
}
