#!/usr/bin/env bash
# Shared helpers for every module — colors, banner, spinner, prompts, OS detection, logging.

C_RESET='\033[0m'; C_DIM='\033[2m'; C_BOLD='\033[1m'
C_CYAN='\033[38;5;51m'; C_BLUE='\033[38;5;69m'; C_PURPLE='\033[38;5;135m'
C_GREEN='\033[38;5;84m'; C_YELLOW='\033[38;5;221m'; C_RED='\033[38;5;203m'; C_GREY='\033[38;5;245m'

LOG_FILE="${LOG_FILE:-/var/log/axion-installer.log}"
mkdir -p "$(dirname "$LOG_FILE")" 2>/dev/null || LOG_FILE="/tmp/axion-installer.log"

log()   { echo "[$(date '+%F %T')] $*" >> "$LOG_FILE"; }
info()  { echo -e "  ${C_CYAN}•${C_RESET} $*"; log "INFO: $*"; }
ok()    { echo -e "  ${C_GREEN}✓${C_RESET} $*"; log "OK: $*"; }
warn()  { echo -e "  ${C_YELLOW}!${C_RESET} $*"; log "WARN: $*"; }
err()   { echo -e "  ${C_RED}✗${C_RESET} $*"; log "ERROR: $*"; }
die()   { err "$*"; echo -e "\n${C_RED}Aborted. Full log: ${LOG_FILE}${C_RESET}\n"; exit 1; }

need_root() {
  if [ "$(id -u)" -ne 0 ]; then
    die "Run this as root (sudo bash installer.sh)."
  fi
}

# Gradient banner: cyan -> blue -> purple, line by line.
banner() {
  clear
  local lines=(
"   █████╗ ██╗  ██╗██╗ ██████╗ ███╗   ██╗"
"  ██╔══██╗╚██╗██╔╝██║██╔═══██╗████╗  ██║"
"  ███████║ ╚███╔╝ ██║██║   ██║██╔██╗ ██║"
"  ██╔══██║ ██╔██╗ ██║██║   ██║██║╚██╗██║"
"  ██║  ██║██╔╝ ██╗██║╚██████╔╝██║ ╚████║"
"  ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝ ╚═════╝ ╚═╝  ╚═══╝"
  )
  local colors=("$C_CYAN" "$C_CYAN" "$C_BLUE" "$C_BLUE" "$C_PURPLE" "$C_PURPLE")
  echo
  for i in "${!lines[@]}"; do
    echo -e "${colors[$i]}${C_BOLD}${lines[$i]}${C_RESET}"
    sleep 0.02
  done
  echo -e "  ${C_GREY}The Axion Installer — panels, bots, tools & themes, one menu.${C_RESET}\n"
}

# Animated spinner wrapped around a command — braille frames cycling cyan→blue→purple.
# Usage: spin "Doing thing..." some_command arg1 arg2
spin() {
  local msg="$1"; shift
  local logf; logf="$(mktemp)"
  "$@" >"$logf" 2>&1 &
  local pid=$!
  local frames='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
  local cols=("$C_CYAN" "$C_CYAN" "$C_CYAN" "$C_BLUE" "$C_BLUE" "$C_BLUE" "$C_PURPLE" "$C_PURPLE" "$C_PURPLE" "$C_BLUE")
  local i=0
  tput civis 2>/dev/null
  while kill -0 "$pid" 2>/dev/null; do
    i=$(((i + 1) % ${#frames}))
    printf "\r  ${cols[$i]}%s${C_RESET} %s" "${frames:$i:1}" "$msg"
    sleep 0.07
  done
  tput cnorm 2>/dev/null
  wait "$pid"; local rc=$?
  if [ $rc -eq 0 ]; then
    printf "\r  ${C_GREEN}✓${C_RESET} %s\n" "$msg"
    log "OK: $msg"
  else
    printf "\r  ${C_RED}✗${C_RESET} %s (failed — see $logf)\n" "$msg"
    log "FAIL: $msg — output in $logf"
    cat "$logf" >> "$LOG_FILE"
    die "'$msg' failed. Last lines:\n$(tail -n 15 "$logf")"
  fi
  rm -f "$logf"
}

# Step progress bar for multi-step flows. Usage: step 3 8 "Installing nginx"
step() {
  local cur="$1" total="$2" label="$3"
  local width=24
  local filled=$((cur * width / total))
  local bar=""
  for ((k = 0; k < width; k++)); do
    if [ $k -lt $filled ]; then bar+="█"; else bar+="░"; fi
  done
  local pct=$((cur * 100 / total))
  echo -e "  ${C_GREY}[${C_PURPLE}${bar}${C_GREY}] ${pct}%${C_RESET}  ${C_BOLD}${label}${C_RESET}  ${C_GREY}(${cur}/${total})${C_RESET}"
}

# One-time animated boot sequence, shown before the first menu of a session.
boot_sequence() {
  local frames='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
  local msgs=("Waking up the engines" "Loading modules" "Warming up the gradients" "Ready")
  tput civis 2>/dev/null
  for m in "${msgs[@]}"; do
    for i in $(seq 0 9); do
      printf "\r  ${C_PURPLE}%s${C_RESET} %s..." "${frames:$((i % ${#frames})):1}" "$m"
      sleep 0.025
    done
  done
  printf "\r%-50s\r" " "
  tput cnorm 2>/dev/null
}

confirm() {
  local prompt="${1:-Continue?}"
  read -rp "$(echo -e "  ${C_YELLOW}?${C_RESET} ${prompt} [y/N]: ")" ans
  [[ "$ans" =~ ^[Yy]$ ]]
}

ask() {
  local prompt="$1" default="${2:-}" ans
  read -rp "$(echo -e "  ${C_BLUE}›${C_RESET} ${prompt}${default:+ [$default]}: ")" ans
  echo "${ans:-$default}"
}

ask_secret() {
  local prompt="$1" ans
  read -rsp "$(echo -e "  ${C_BLUE}›${C_RESET} ${prompt}: ")" ans
  echo >&2
  echo "$ans"
}

detect_os() {
  if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS_ID="$ID"; OS_VER="${VERSION_ID%%.*}"
  else
    die "Cannot detect OS (/etc/os-release missing)."
  fi
  case "$OS_ID" in
    ubuntu|debian) : ;;
    *) die "Unsupported OS: $OS_ID. This installer supports Ubuntu/Debian." ;;
  esac
  export OS_ID OS_VER
}

press_enter() { read -rp "$(echo -e "\n  ${C_GREY}Press Enter to continue...${C_RESET}")" _; }

hr() { echo -e "  ${C_GREY}────────────────────────────────────────────${C_RESET}"; }
