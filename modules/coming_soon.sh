#!/usr/bin/env bash
# Generic "coming soon" placeholder for menu entries that aren't built yet.
# Usage: coming_soon "PufferPanel"
coming_soon() {
  local name="$1"
  hr
  echo -e "  ${C_PURPLE}${C_BOLD}${name}${C_RESET} — ${C_YELLOW}coming soon${C_RESET}"
  echo -e "  ${C_GREY}Not wired up yet — ping CUBE/devhub201 if you want this prioritized.${C_RESET}"
  hr
  press_enter
}
