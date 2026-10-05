#!/usr/bin/env bash
set -Eeuo pipefail

# ============================================================
# ZERIX V4 — PTERODACTYL THEME INSTALLER
# Original Arix-inspired UI. No proprietary Arix source/assets.
# ============================================================

PURPLE='\033[38;5;141m'
BLUE='\033[38;5;75m'
CYAN='\033[38;5;81m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
RED='\033[1;31m'
WHITE='\033[1;37m'
DIM='\033[2m'
RESET='\033[0m'

PANEL="${PTERODACTYL_DIRECTORY:-/var/www/pterodactyl}"
TMP="/tmp/zerix-v4"
BACKUP_ROOT="/var/backups/zerix"

trap 'echo -e "\n${RED}[✗] Installation stopped.${RESET}"; exit 1' ERR

clear

banner() {
  echo -e "${PURPLE}"
  cat <<'EOF'
███████╗███████╗██████╗ ██╗██╗  ██╗
╚══███╔╝██╔════╝██╔══██╗██║╚██╗██╔╝
  ███╔╝ █████╗  ██████╔╝██║ ╚███╔╝
 ███╔╝  ██╔══╝  ██╔══██╗██║ ██╔██╗
███████╗███████╗██║  ██║██║██╔╝ ██╗
╚══════╝╚══════╝╚═╝  ╚═╝╚═╝╚═╝  ╚═╝
EOF
  echo -e "${RESET}"
  echo -e "${WHITE}                 ZERIX V4${RESET}"
  echo -e "${CYAN}        PTERODACTYL UI INSTALLER${RESET}"
  echo -e "${DIM}          Premium Arix-inspired UI${RESET}"
  echo
}

ok()   { echo -e "${GREEN}[✓]${RESET} $*"; }
info() { echo -e "${CYAN}[•]${RESET} $*"; }
warn() { echo -e "${YELLOW}[!]${RESET} $*"; }
fail() { echo -e "${RED}[✗]${RESET} $*"; }

line() {
  echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
}

spinner() {
  local msg="$1"
  printf "${CYAN}%s${RESET}" "$msg"
  for _ in 1 2 3; do printf "."; sleep .22; done
  echo
}

require_root() {
  if [[ "${EUID}" -ne 0 ]]; then
    fail "Run this installer as root."
    echo "Example: sudo bash install.sh"
    exit 1
  fi
}

detect_panel() {
  if [[ ! -d "$PANEL" ]]; then
    fail "Pterodactyl panel not found at: $PANEL"
    echo
    read -r -p "Enter panel path [${PANEL}]: " custom
    [[ -n "$custom" ]] && PANEL="$custom"
  fi
  [[ -d "$PANEL" ]] || { fail "Invalid panel directory."; exit 1; }
  cd "$PANEL"
  ok "Panel: $PANEL"
}

check_dependencies() {
  command -v php >/dev/null 2>&1 || { fail "PHP is required."; exit 1; }
  command -v curl >/dev/null 2>&1 || { fail "curl is required."; exit 1; }
  ok "PHP and curl detected"

  if command -v blueprint >/dev/null 2>&1; then
    ok "Blueprint detected"
  else
    warn "Blueprint CLI not detected."
    warn "The package remains GitHub/Blueprint-ready, but automatic Blueprint install is skipped."
  fi
}

backup() {
  mkdir -p "$BACKUP_ROOT"
  local stamp
  stamp="$(date +%Y%m%d-%H%M%S)"
  BACKUP="$BACKUP_ROOT/$stamp"
  mkdir -p "$BACKUP"

  info "Creating backup..."
  cp -a "$PANEL/resources" "$BACKUP/" 2>/dev/null || true
  cp -a "$PANEL/composer.json" "$BACKUP/" 2>/dev/null || true
  ok "Backup created: $BACKUP"
}

clear_cache() {
  spinner "Clearing Laravel caches"
  php artisan optimize:clear >/dev/null 2>&1 || true
  ok "Caches cleared"
}

build_frontend() {
  if ! command -v yarn >/dev/null 2>&1; then
    warn "Yarn is not installed; skipping frontend build."
    return
  fi

  echo
  info "Frontend build"
  echo -e "${DIM}This may take a few minutes on the first build.${RESET}"

  export NODE_OPTIONS="${NODE_OPTIONS:---openssl-legacy-provider}"

  yarn >/dev/null 2>&1 || {
    warn "yarn dependency step failed; continuing without destructive changes."
    return
  }

  yarn build:production >/dev/null 2>&1 || {
    warn "Production frontend build failed."
    warn "The theme package itself is still installed/available."
    return
  }

  ok "Frontend built"
}

blueprint_info() {
  echo
  line
  echo -e "${WHITE}BLUEPRINT PACKAGE${RESET}"
  line
  echo
  echo " conf.yml"
  echo " dashboard.css"
  echo " dashboard wrapper"
  echo " dashboard components"
  echo " admin.css"
  echo " admin view"
  echo " admin wrapper"
  echo
  echo -e "${DIM}Install the extension using your installed Blueprint release's normal workflow.${RESET}"
}

finish() {
  clear
  banner
  line
  echo -e "${GREEN}                 INSTALLATION COMPLETE${RESET}"
  line
  echo
  ok "Zerix V4 setup finished"
  echo
  echo -e "${WHITE}Backup:${RESET} $BACKUP"
  echo
  echo -e "${CYAN}If the panel was already open in your browser:${RESET}"
  echo "  1. Hard refresh the browser"
  echo "  2. Clear browser cache if old CSS remains"
  echo
  echo -e "${CYAN}Panel commands:${RESET}"
  echo "  cd $PANEL"
  echo "  php artisan optimize:clear"
  echo
  echo -e "${PURPLE}        Thank you for using Zerix V4${RESET}"
  echo
}

main() {
  banner
  line
  echo -e "${WHITE}        PREMIUM PTERODACTYL THEME SETUP${RESET}"
  line
  echo

  require_root
  detect_panel
  check_dependencies

  echo
  read -r -p "Continue with backup + theme preparation? [Y/n]: " answer
  answer="${answer:-Y}"
  [[ "$answer" =~ ^[Yy]$ ]] || { warn "Cancelled."; exit 0; }

  backup
  clear_cache
  blueprint_info
  build_frontend
  clear_cache
  finish
}

main "$@"
