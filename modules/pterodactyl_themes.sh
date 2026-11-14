#!/usr/bin/env bash
# Pterodactyl theming: Blueprint (the extension framework most modern free themes build
# on) + 5 popular, actually-free/open-source theme & theme-extension picks.
#
# Sources (verified via github.com/topics/pterodactyl-theme — real public repos, no
# paid/marketplace-only resources):
#   Nookure/NookTheme                 — full standalone free theme
#   blueprint-community/extension-darkenate — Blueprint dark theme (bloom.host colors)
#   sp11rum/recolor                   — Blueprint recolor extension
#   fernsehheft/Abyss-Purple          — Blueprint purple dark theme
#   davinmaritza/pterodactyl-espresso-theme — standalone dark minimalist theme

_panel_dir_or_die() {
  local d; d=$(ask "Pterodactyl Panel install path" "/var/www/pterodactyl")
  [ -f "$d/artisan" ] || die "No panel found at $d (artisan missing) — install the panel first."
  echo "$d"
}

install_blueprint() {
  need_root; hr
  echo -e "  ${C_PURPLE}${C_BOLD}Blueprint${C_RESET} — Pterodactyl extension framework"
  echo -e "  ${C_GREY}Required by most modern free themes (install this first).${C_RESET}"
  hr
  local PANEL; PANEL=$(_panel_dir_or_die)
  if [ -f "$PANEL/blueprint.sh" ]; then
    ok "Blueprint already installed at $PANEL."
    press_enter; return
  fi

  spin "Installing zip/unzip/git/curl/wget" apt-get install -y zip unzip git curl wget
  if ! command -v node >/dev/null 2>&1 || [ "$(node -v | sed 's/v//;s/\..*//')" -lt 18 ]; then
    spin "Installing Node.js 20" bash -c "curl -fsSL https://deb.nodesource.com/setup_20.x | bash - && apt-get install -y nodejs"
  fi
  command -v yarn >/dev/null 2>&1 || spin "Installing yarn" npm install -g yarn
  pushd "$PANEL" >/dev/null
  spin "yarn install (panel frontend deps)" yarn install

  spin "Downloading latest Blueprint release" bash -c \
    "wget -q \"\$(curl -s https://api.github.com/repos/BlueprintFramework/framework/releases/latest | grep browser_download_url | cut -d '\"' -f4)\" -O release.zip"
  spin "Unpacking Blueprint into panel" unzip -o release.zip
  rm -f release.zip

  [ -f .blueprintrc ] || echo 'WEBUSER="www-data"; OWNERSHIP="www-data:www-data"; USERSHELL="/bin/bash";' > .blueprintrc
  chmod +x blueprint.sh
  info "Running Blueprint's own installer..."
  bash blueprint.sh || die "blueprint.sh failed — see output above."
  popd >/dev/null
  hr; ok "Blueprint installed. You can now install Blueprint-based theme extensions below."
  press_enter
}

_install_blueprint_extension() {
  local REPO="$1" NAME="$2"
  need_root; hr
  echo -e "  ${C_PURPLE}${C_BOLD}${NAME}${C_RESET}"
  hr
  local PANEL; PANEL=$(_panel_dir_or_die)
  [ -f "$PANEL/blueprint.sh" ] || die "Blueprint isn't installed on this panel yet — run 'Blueprint Framework' first."

  local ASSET
  ASSET=$(curl -fsSL "https://api.github.com/repos/${REPO}/releases/latest" | grep browser_download_url | grep -o 'https://[^"]*\.blueprint' | head -n1)
  if [ -z "$ASSET" ]; then
    warn "No pre-built .blueprint release asset found for ${REPO}."
    echo -e "  ${C_GREY}Check https://github.com/${REPO}/releases manually — some extensions only"
    echo -e "  publish source, and need building per the repo's own README.${C_RESET}"
    press_enter; return
  fi
  local FILE; FILE=$(basename "$ASSET")
  pushd "$PANEL" >/dev/null
  spin "Downloading ${NAME}" curl -fsSL -o "$FILE" "$ASSET"
  info "Installing via Blueprint..."
  if bash blueprint.sh -i "$FILE" 2>/dev/null || ./blueprint.sh -i "$FILE" 2>/dev/null; then
    ok "${NAME} installed."
  else
    warn "Blueprint's -i flag may differ on this version — try manually: cd ${PANEL} && blueprint -i ${FILE}"
  fi
  popd >/dev/null
  hr; press_enter
}

theme_darkenate()     { _install_blueprint_extension "blueprint-community/extension-darkenate" "Darkenate (dark theme)"; }
theme_recolor()       { _install_blueprint_extension "sp11rum/recolor" "Recolor (accent-color extension)"; }
theme_abyss_purple()  { _install_blueprint_extension "fernsehheft/Abyss-Purple" "Abyss Purple (dark purple theme)"; }

_clone_theme_repo() {
  local REPO_URL="$1" NAME="$2"
  need_root; hr
  echo -e "  ${C_PURPLE}${C_BOLD}${NAME}${C_RESET}"
  hr
  local PANEL; PANEL=$(_panel_dir_or_die)
  local TMP; TMP=$(mktemp -d)
  spin "Cloning ${NAME}" git clone --depth 1 "$REPO_URL" "$TMP"
  if [ -f "$TMP/install.sh" ]; then
    ( cd "$PANEL" && bash "$TMP/install.sh" ) || die "${NAME}'s install.sh failed."
  else
    warn "${NAME} has no install.sh — copying resources/public and rebuilding assets."
    confirm "Proceed? (back up $PANEL first if unsure)" || { rm -rf "$TMP"; press_enter; return; }
    [ -d "$TMP/resources" ] && cp -r "$TMP/resources/." "$PANEL/resources/"
    [ -d "$TMP/public" ] && cp -r "$TMP/public/." "$PANEL/public/"
    pushd "$PANEL" >/dev/null
    command -v yarn >/dev/null 2>&1 || spin "Installing yarn" npm install -g yarn
    spin "yarn install" yarn install
    spin "Building assets" yarn build:production
    popd >/dev/null
  fi
  rm -rf "$TMP"
  hr; ok "${NAME} applied — hard-refresh the panel in your browser."
  press_enter
}

theme_nooktheme() { _clone_theme_repo "https://github.com/Nookure/NookTheme" "NookTheme"; }
theme_espresso()  { _clone_theme_repo "https://github.com/davinmaritza/pterodactyl-espresso-theme" "Espresso Theme"; }
