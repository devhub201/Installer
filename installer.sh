#!/usr/bin/env bash
# The Axion Installer — one menu for panels, bots, tools & themes.
# Usage:  bash <(curl -fsSL https://raw.githubusercontent.com/devhub201/installer/main/bootstrap.sh)
#     or: git clone https://github.com/devhub201/installer && cd installer && sudo bash installer.sh
set -uo pipefail

SELF_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SELF_DIR/lib/common.sh"
source "$SELF_DIR/modules/coming_soon.sh"
source "$SELF_DIR/modules/pterodactyl_panel.sh"
source "$SELF_DIR/modules/pterodactyl_wings.sh"
source "$SELF_DIR/modules/pufferpanel.sh"
source "$SELF_DIR/modules/cloudpanel.sh"
source "$SELF_DIR/modules/avm_bot.sh"
source "$SELF_DIR/modules/axionhost_tickets.sh"
source "$SELF_DIR/modules/tools.sh"
source "$SELF_DIR/modules/theme_generic.sh"

panels_menu() {
  while true; do
    banner
    echo -e "  ${C_BOLD}Panels${C_RESET}"
    hr
    echo -e "   ${C_CYAN}1)${C_RESET} Pterodactyl Panel          ${C_GREEN}ready${C_RESET}"
    echo -e "   ${C_CYAN}2)${C_RESET} Pterodactyl Wings (node)   ${C_GREEN}ready${C_RESET}"
    echo -e "   ${C_CYAN}3)${C_RESET} PufferPanel                ${C_GREEN}ready${C_RESET}"
    echo -e "   ${C_CYAN}4)${C_RESET} CloudPanel                 ${C_GREEN}ready${C_RESET}"
    echo -e "   ${C_CYAN}0)${C_RESET} ← Back"
    hr
    read -rp "$(echo -e "  ${C_BLUE}›${C_RESET} Choose: ")" c
    case "$c" in
      1) install_pterodactyl_panel ;;
      2) install_pterodactyl_wings ;;
      3) install_pufferpanel ;;
      4) install_cloudpanel ;;
      0) return ;;
      *) warn "Invalid choice"; sleep 1 ;;
    esac
  done
}

bots_menu() {
  while true; do
    banner
    echo -e "  ${C_BOLD}Bots${C_RESET}"
    hr
    echo -e "   ${C_CYAN}1)${C_RESET} AVM-Pro (AxionHost Discord VPS bot)   ${C_GREEN}ready${C_RESET}"
    echo -e "   ${C_CYAN}2)${C_RESET} AxionHost Tickets (AI support bot)    ${C_GREEN}ready${C_RESET}"
    echo -e "   ${C_CYAN}0)${C_RESET} ← Back"
    hr
    read -rp "$(echo -e "  ${C_BLUE}›${C_RESET} Choose: ")" c
    case "$c" in
      1) install_avm_bot ;;
      2) install_axionhost_tickets ;;
      0) return ;;
      *) warn "Invalid choice"; sleep 1 ;;
    esac
  done
}

tools_menu() {
  while true; do
    banner
    echo -e "  ${C_BOLD}Tools${C_RESET}"
    hr
    echo -e "   ${C_CYAN}1)${C_RESET} Add swap"
    echo -e "   ${C_CYAN}2)${C_RESET} Basic firewall (ufw)"
    echo -e "   ${C_CYAN}3)${C_RESET} Fail2ban (SSH brute-force protection)"
    echo -e "   ${C_CYAN}4)${C_RESET} Install Docker (standalone)"
    echo -e "   ${C_CYAN}5)${C_RESET} Quick server benchmark"
    echo -e "   ${C_CYAN}0)${C_RESET} ← Back"
    hr
    read -rp "$(echo -e "  ${C_BLUE}›${C_RESET} Choose: ")" c
    case "$c" in
      1) tool_add_swap ;;
      2) tool_firewall ;;
      3) tool_fail2ban ;;
      4) tool_docker ;;
      5) tool_benchmark ;;
      0) return ;;
      *) warn "Invalid choice"; sleep 1 ;;
    esac
  done
}

themes_menu() {
  while true; do
    banner
    echo -e "  ${C_BOLD}Themes${C_RESET}"
    hr
    echo -e "   ${C_CYAN}1)${C_RESET} Apply a Pterodactyl theme (from git URL)   ${C_GREEN}ready${C_RESET}"
    echo -e "   ${C_CYAN}0)${C_RESET} ← Back"
    hr
    read -rp "$(echo -e "  ${C_BLUE}›${C_RESET} Choose: ")" c
    case "$c" in
      1) apply_pterodactyl_theme ;;
      0) return ;;
      *) warn "Invalid choice"; sleep 1 ;;
    esac
  done
}

main_menu() {
  while true; do
    banner
    echo -e "  ${C_CYAN}1)${C_RESET} Panels"
    echo -e "  ${C_CYAN}2)${C_RESET} Bots"
    echo -e "  ${C_CYAN}3)${C_RESET} Tools"
    echo -e "  ${C_CYAN}4)${C_RESET} Themes"
    echo -e "  ${C_CYAN}0)${C_RESET} Exit"
    hr
    read -rp "$(echo -e "  ${C_BLUE}›${C_RESET} Choose: ")" choice
    case "$choice" in
      1) panels_menu ;;
      2) bots_menu ;;
      3) tools_menu ;;
      4) themes_menu ;;
      0) echo; exit 0 ;;
      *) warn "Invalid choice"; sleep 1 ;;
    esac
  done
}

main_menu
