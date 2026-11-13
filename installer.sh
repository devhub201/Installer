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
source "$SELF_DIR/modules/bots_generic.sh"
source "$SELF_DIR/modules/tools.sh"
source "$SELF_DIR/modules/tools_system.sh"
source "$SELF_DIR/modules/tools_security.sh"
source "$SELF_DIR/modules/tools_webdb.sh"
source "$SELF_DIR/modules/tools_docker.sh"
source "$SELF_DIR/modules/tools_monitoring.sh"
source "$SELF_DIR/modules/tools_network.sh"
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
    echo -e "   ${C_CYAN}3)${C_RESET} Deploy any bot from a git repo        ${C_GREEN}ready${C_RESET}"
    echo -e "   ${C_CYAN}0)${C_RESET} ← Back"
    hr
    read -rp "$(echo -e "  ${C_BLUE}›${C_RESET} Choose: ")" c
    case "$c" in
      1) install_avm_bot ;;
      2) install_axionhost_tickets ;;
      3) deploy_generic_bot ;;
      0) return ;;
      *) warn "Invalid choice"; sleep 1 ;;
    esac
  done
}

tools_system_menu() {
  while true; do
    banner; echo -e "  ${C_BOLD}Tools › System${C_RESET}"; hr
    echo -e "   ${C_CYAN}1)${C_RESET} Update & upgrade system"
    echo -e "   ${C_CYAN}2)${C_RESET} Add swap"
    echo -e "   ${C_CYAN}3)${C_RESET} Create a sudo user"
    echo -e "   ${C_CYAN}4)${C_RESET} Set hostname"
    echo -e "   ${C_CYAN}5)${C_RESET} Set timezone"
    echo -e "   ${C_CYAN}6)${C_RESET} Dev basics (build-essential, git, curl, wget, unzip)"
    echo -e "   ${C_CYAN}7)${C_RESET} CLI tools (htop, btop, tmux, screen, neofetch)"
    echo -e "   ${C_CYAN}8)${C_RESET} Disk cleanup (apt/journal/docker)"
    echo -e "   ${C_CYAN}9)${C_RESET} Custom login banner (MOTD)"
    echo -e "   ${C_CYAN}0)${C_RESET} ← Back"
    hr; read -rp "$(echo -e "  ${C_BLUE}›${C_RESET} Choose: ")" c
    case "$c" in
      1) sys_update ;; 2) tool_add_swap ;; 3) sys_add_user ;; 4) sys_hostname ;;
      5) sys_timezone ;; 6) sys_dev_basics ;; 7) sys_cli_tools ;; 8) sys_cleanup ;; 9) sys_motd ;;
      0) return ;; *) warn "Invalid choice"; sleep 1 ;;
    esac
  done
}

tools_security_menu() {
  while true; do
    banner; echo -e "  ${C_BOLD}Tools › Security${C_RESET}"; hr
    echo -e "   ${C_CYAN}1)${C_RESET} Basic firewall (ufw)"
    echo -e "   ${C_CYAN}2)${C_RESET} Fail2ban (SSH brute-force protection)"
    echo -e "   ${C_CYAN}3)${C_RESET} SSH hardening (root login / password auth / port)"
    echo -e "   ${C_CYAN}4)${C_RESET} Automatic security updates"
    echo -e "   ${C_CYAN}5)${C_RESET} ClamAV virus scan"
    echo -e "   ${C_CYAN}6)${C_RESET} rkhunter (rootkit hunter)"
    echo -e "   ${C_CYAN}0)${C_RESET} ← Back"
    hr; read -rp "$(echo -e "  ${C_BLUE}›${C_RESET} Choose: ")" c
    case "$c" in
      1) tool_firewall ;; 2) tool_fail2ban ;; 3) sys_ssh_hardening ;;
      4) sys_unattended_upgrades ;; 5) sec_clamav ;; 6) sec_rkhunter ;;
      0) return ;; *) warn "Invalid choice"; sleep 1 ;;
    esac
  done
}

tools_webdb_menu() {
  while true; do
    banner; echo -e "  ${C_BOLD}Tools › Web & Database${C_RESET}"; hr
    echo -e "   ${C_CYAN}1)${C_RESET} nginx"
    echo -e "   ${C_CYAN}2)${C_RESET} Apache"
    echo -e "   ${C_CYAN}3)${C_RESET} MariaDB"
    echo -e "   ${C_CYAN}4)${C_RESET} PostgreSQL"
    echo -e "   ${C_CYAN}5)${C_RESET} Redis"
    echo -e "   ${C_CYAN}6)${C_RESET} phpMyAdmin"
    echo -e "   ${C_CYAN}7)${C_RESET} Certbot SSL for an existing site"
    echo -e "   ${C_CYAN}8)${C_RESET} Node.js + npm"
    echo -e "   ${C_CYAN}9)${C_RESET} Python3 + pip + venv"
    echo -e "   ${C_CYAN}10)${C_RESET} Composer"
    echo -e "   ${C_CYAN}11)${C_RESET} Quick static site (folder + nginx + SSL)"
    echo -e "   ${C_CYAN}0)${C_RESET} ← Back"
    hr; read -rp "$(echo -e "  ${C_BLUE}›${C_RESET} Choose: ")" c
    case "$c" in
      1) web_nginx ;; 2) web_apache ;; 3) web_mariadb ;; 4) web_postgres ;; 5) web_redis ;;
      6) web_phpmyadmin ;; 7) web_certbot_standalone ;; 8) web_nodejs ;; 9) web_python ;;
      10) web_composer ;; 11) web_static_site ;;
      0) return ;; *) warn "Invalid choice"; sleep 1 ;;
    esac
  done
}

tools_docker_menu() {
  while true; do
    banner; echo -e "  ${C_BOLD}Tools › Docker & Apps${C_RESET}"; hr
    echo -e "   ${C_CYAN}1)${C_RESET} Docker Engine (standalone)"
    echo -e "   ${C_CYAN}2)${C_RESET} Portainer (Docker web UI)"
    echo -e "   ${C_CYAN}3)${C_RESET} Nginx Proxy Manager"
    echo -e "   ${C_CYAN}4)${C_RESET} Uptime Kuma (status page)"
    echo -e "   ${C_CYAN}5)${C_RESET} n8n (automation)"
    echo -e "   ${C_CYAN}6)${C_RESET} MinIO (S3-compatible storage)"
    echo -e "   ${C_CYAN}7)${C_RESET} Watchtower (auto-update containers)"
    echo -e "   ${C_CYAN}8)${C_RESET} WireGuard VPN (wg-easy, web UI)"
    echo -e "   ${C_CYAN}0)${C_RESET} ← Back"
    hr; read -rp "$(echo -e "  ${C_BLUE}›${C_RESET} Choose: ")" c
    case "$c" in
      1) tool_docker ;; 2) docker_portainer ;; 3) docker_nginx_proxy_manager ;;
      4) docker_uptime_kuma ;; 5) docker_n8n ;; 6) docker_minio ;; 7) docker_watchtower ;;
      8) docker_wireguard_easy ;;
      0) return ;; *) warn "Invalid choice"; sleep 1 ;;
    esac
  done
}

tools_monitoring_menu() {
  while true; do
    banner; echo -e "  ${C_BOLD}Tools › Monitoring${C_RESET}"; hr
    echo -e "   ${C_CYAN}1)${C_RESET} Netdata (real-time dashboard)"
    echo -e "   ${C_CYAN}2)${C_RESET} vnstat (bandwidth monitor)"
    echo -e "   ${C_CYAN}3)${C_RESET} Grafana"
    echo -e "   ${C_CYAN}4)${C_RESET} Prometheus"
    echo -e "   ${C_CYAN}5)${C_RESET} Quick server benchmark"
    echo -e "   ${C_CYAN}0)${C_RESET} ← Back"
    hr; read -rp "$(echo -e "  ${C_BLUE}›${C_RESET} Choose: ")" c
    case "$c" in
      1) mon_netdata ;; 2) mon_vnstat ;; 3) mon_grafana ;; 4) mon_prometheus ;; 5) tool_benchmark ;;
      0) return ;; *) warn "Invalid choice"; sleep 1 ;;
    esac
  done
}

tools_network_menu() {
  while true; do
    banner; echo -e "  ${C_BOLD}Tools › Network & Backup${C_RESET}"; hr
    echo -e "   ${C_CYAN}1)${C_RESET} Tailscale"
    echo -e "   ${C_CYAN}2)${C_RESET} vsftpd (FTP server)"
    echo -e "   ${C_CYAN}3)${C_RESET} rclone (cloud storage sync)"
    echo -e "   ${C_CYAN}4)${C_RESET} Scheduled backup (tar + cron, auto-rotate)"
    echo -e "   ${C_CYAN}0)${C_RESET} ← Back"
    hr; read -rp "$(echo -e "  ${C_BLUE}›${C_RESET} Choose: ")" c
    case "$c" in
      1) net_tailscale ;; 2) net_vsftpd ;; 3) net_rclone ;; 4) net_backup_cron ;;
      0) return ;; *) warn "Invalid choice"; sleep 1 ;;
    esac
  done
}

tools_menu() {
  while true; do
    banner
    echo -e "  ${C_BOLD}Tools${C_RESET}  ${C_GREY}— 35+ one-shot admin tools, grouped${C_RESET}"
    hr
    echo -e "   ${C_CYAN}1)${C_RESET} System"
    echo -e "   ${C_CYAN}2)${C_RESET} Security"
    echo -e "   ${C_CYAN}3)${C_RESET} Web & Database"
    echo -e "   ${C_CYAN}4)${C_RESET} Docker & Apps"
    echo -e "   ${C_CYAN}5)${C_RESET} Monitoring"
    echo -e "   ${C_CYAN}6)${C_RESET} Network & Backup"
    echo -e "   ${C_CYAN}0)${C_RESET} ← Back"
    hr
    read -rp "$(echo -e "  ${C_BLUE}›${C_RESET} Choose: ")" c
    case "$c" in
      1) tools_system_menu ;;
      2) tools_security_menu ;;
      3) tools_webdb_menu ;;
      4) tools_docker_menu ;;
      5) tools_monitoring_menu ;;
      6) tools_network_menu ;;
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

boot_sequence
main_menu
