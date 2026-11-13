#!/usr/bin/env bash
# Installs CUBE's own AxionHost/AVM-Pro Discord VPS-hosting bot by delegating to its
# own installer, so logic never has to be duplicated/kept in sync in two places.

install_avm_bot() {
  need_root
  hr
  echo -e "  ${C_PURPLE}${C_BOLD}AVM-Pro${C_RESET} — AxionHost Discord VPS-hosting bot"
  hr
  local DEST
  DEST=$(ask "Install directory" "/opt/avm-pro")

  if [ -d "$DEST/.git" ]; then
    info "Already cloned at $DEST — pulling latest instead of re-cloning."
    spin "Updating AVM-Pro" git -C "$DEST" pull --ff-only
  else
    spin "Cloning AVM-Pro" git clone --depth 1 https://github.com/devhub201/AVM-Pro "$DEST"
  fi

  if [ -x "$DEST/install.sh" ]; then
    info "Handing off to AVM-Pro's own installer (same one you already know) ..."
    hr
    bash "$DEST/install.sh"
  else
    die "install.sh not found/executable in $DEST — check the AVM-Pro repo."
  fi
  hr
  press_enter
}
