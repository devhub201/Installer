#!/usr/bin/env bash
# Generic Pterodactyl theme installer — applies any community theme from its git repo.
# Deliberately generic rather than hardcoding specific theme URLs: theme repos change
# hands/go stale often, and guessing one here would risk running something unverified.

apply_pterodactyl_theme() {
  need_root
  hr
  echo -e "  ${C_PURPLE}${C_BOLD}Apply a Pterodactyl Theme${C_RESET}"
  hr
  local PANEL_DIR; PANEL_DIR=$(ask "Pterodactyl Panel install path" "/var/www/pterodactyl")
  [ -d "$PANEL_DIR" ] || die "No panel found at $PANEL_DIR — install the panel first."

  echo -e "  ${C_GREY}Point this at the theme's own git repo — most Pterodactyl themes ship as a"
  echo -e "  patch/overlay on the panel's resources + public folders with their own build step.${C_RESET}"
  local REPO; REPO=$(ask "Theme git repo URL (blank = cancel)")
  [ -z "$REPO" ] && { warn "Cancelled."; press_enter; return; }

  local TMP; TMP=$(mktemp -d)
  spin "Cloning theme" git clone --depth 1 "$REPO" "$TMP"

  if [ -f "$TMP/install.sh" ]; then
    info "Theme ships its own install.sh — running that (most reliable path)."
    ( cd "$PANEL_DIR" && bash "$TMP/install.sh" ) || die "Theme's install.sh failed."
  else
    warn "No install.sh in the theme repo — copying resources/public over and rebuilding assets."
    confirm "Proceed with a generic copy + 'yarn build:production'? (back up $PANEL_DIR first if unsure)" || { rm -rf "$TMP"; return; }
    [ -d "$TMP/resources" ] && cp -r "$TMP/resources/." "$PANEL_DIR/resources/"
    [ -d "$TMP/public" ] && cp -r "$TMP/public/." "$PANEL_DIR/public/"
    pushd "$PANEL_DIR" >/dev/null
    command -v yarn >/dev/null 2>&1 || spin "Installing yarn" npm install -g yarn
    spin "yarn install" yarn install
    spin "Building theme assets" yarn build:production
    popd >/dev/null
  fi
  rm -rf "$TMP"
  hr
  ok "Theme applied. Hard-refresh the panel in your browser to see it."
  hr
  press_enter
}
