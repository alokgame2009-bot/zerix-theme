#!/usr/bin/env bash
set -Eeuo pipefail

# ============================================================
# ZERIX THEME INSTALLER
# Power by SkylerNodes | Made by Zyren
# ============================================================

VERSION="1.0.0"
PANEL="${ZERIX_PANEL_PATH:-/var/www/pterodactyl}"
# Set this after creating your GitHub repo. Example:
# https://raw.githubusercontent.com/USERNAME/REPOSITORY/main
REPO_RAW_BASE="${ZERIX_REPO_RAW_BASE:-https://raw.githubusercontent.com/YOUR_USERNAME/YOUR_REPOSITORY/main}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd || true)"
LOCAL_RESOURCES="$SCRIPT_DIR/resources"
STAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP_ROOT="$PANEL/storage/zerix-theme-backup"
BACKUP="$BACKUP_ROOT/$STAMP"
INDEX="$PANEL/resources/scripts/index.tsx"
THEME_DIR="$PANEL/resources/scripts/Zerix"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'

say(){ printf "${CYAN}[ZERIX]${NC} %s\n" "$*"; }
ok(){ printf "${GREEN}[  OK  ]${NC} %s\n" "$*"; }
warn(){ printf "${YELLOW}[ WARN ]${NC} %s\n" "$*"; }
die(){ printf "${RED}[ ERROR]${NC} %s\n" "$*" >&2; exit 1; }

banner(){
  clear 2>/dev/null || true
  printf '\n'
  printf '                 ZERIX\n'
  printf '                  THEME\n'
  printf '        Zerix Theme Installer\n'
  printf '        Power by SkylerNodes\n'
  printf '        Made by Zyren\n'
  printf '        Version %s\n' "$VERSION"
  printf '\n'
  printf '  ────────────────────────────────────────────────\n'
  printf '    [1]  Zerix Theme Install\n'
  printf '    [2]  Theme Uninstall\n'
  printf '    [3]  Theme Update\n'
  printf '    [0]  Exit\n'
  printf '  ────────────────────────────────────────────────\n\n'
}

require_root(){ [[ $EUID -eq 0 ]] || die "Run as root: sudo bash zerix.sh"; }
validate_panel(){
  [[ -d "$PANEL" ]] || die "Pterodactyl directory not found: $PANEL"
  [[ -f "$INDEX" ]] || die "Frontend index not found: $INDEX"
}

load_resources(){
  if [[ -d "$LOCAL_RESOURCES/scripts/Zerix" ]]; then
    RESOURCE_DIR="$LOCAL_RESOURCES"
    return
  fi

  [[ "$REPO_RAW_BASE" != *YOUR_USERNAME* ]] || die "Configure REPO_RAW_BASE in zerix.sh before using the GitHub one-command installer."
  TMP_DIR="$(mktemp -d)"
  trap 'rm -rf "${TMP_DIR:-}"' RETURN
  say "Downloading ZERIX files from GitHub..."
  mkdir -p "$TMP_DIR/resources/scripts/Zerix/assets"
  curl -fsSL "$REPO_RAW_BASE/resources/scripts/Zerix/main.css" -o "$TMP_DIR/resources/scripts/Zerix/main.css"
  curl -fsSL "$REPO_RAW_BASE/resources/scripts/Zerix/theme.ts" -o "$TMP_DIR/resources/scripts/Zerix/theme.ts"
  curl -fsSL "$REPO_RAW_BASE/resources/scripts/Zerix/assets/zerix-icon.svg" -o "$TMP_DIR/resources/scripts/Zerix/assets/zerix-icon.svg"
  curl -fsSL "$REPO_RAW_BASE/resources/scripts/Zerix/assets/theme.json" -o "$TMP_DIR/resources/scripts/Zerix/assets/theme.json"
  RESOURCE_DIR="$TMP_DIR/resources"
}

backup_current(){
  mkdir -p "$BACKUP"
  cp -a "$INDEX" "$BACKUP/index.tsx"
  if [[ -d "$THEME_DIR" ]]; then cp -a "$THEME_DIR" "$BACKUP/Zerix"; fi
  [[ -f "$PANEL/public/assets/zerix-icon.svg" ]] && cp -a "$PANEL/public/assets/zerix-icon.svg" "$BACKUP/zerix-icon.svg" || true
  [[ -f "$PANEL/public/assets/zerix-theme.json" ]] && cp -a "$PANEL/public/assets/zerix-theme.json" "$BACKUP/zerix-theme.json" || true
  echo "$BACKUP" > "$BACKUP_ROOT/latest"
  say "Backup created: $BACKUP"
}

add_imports(){
  local css="import './Zerix/main.css';"
  local ts="import './Zerix/theme.ts';"
  grep -Fqx "$css" "$INDEX" || sed -i "1i $css" "$INDEX"
  grep -Fqx "$ts" "$INDEX" || sed -i "2i $ts" "$INDEX"
}

remove_imports(){
  sed -i "/^import ['\"]\.\/Zerix\/main\.css['\"];$/d" "$INDEX" || true
  sed -i "/^import ['\"]\.\/Zerix\/theme\.ts['\"];$/d" "$INDEX" || true
}

build_panel(){
  cd "$PANEL"
  if command -v yarn >/dev/null 2>&1 && [[ -f yarn.lock ]]; then
    say "Building frontend with Yarn..."
    yarn build:production
  elif command -v npm >/dev/null 2>&1 && [[ -f package.json ]]; then
    say "Building frontend with npm..."
    npm run build:production
  else
    die "No Yarn/npm build environment found."
  fi
  php artisan view:clear >/dev/null 2>&1 || true
  php artisan config:clear >/dev/null 2>&1 || true
}

install_theme(){
  require_root; validate_panel; load_resources
  echo
  say "Installing ZERIX Theme v$VERSION"
  backup_current
  mkdir -p "$THEME_DIR"
  cp -a "$RESOURCE_DIR/scripts/Zerix/." "$THEME_DIR/"
  mkdir -p "$PANEL/public/assets"
  cp -f "$RESOURCE_DIR/scripts/Zerix/assets/zerix-icon.svg" "$PANEL/public/assets/zerix-icon.svg"
  cp -f "$RESOURCE_DIR/scripts/Zerix/assets/theme.json" "$PANEL/public/assets/zerix-theme.json"
  add_imports
  build_panel
  ok "ZERIX Theme installed successfully."
  ok "Backup: $BACKUP"
}

update_theme(){
  require_root; validate_panel
  echo
  say "Updating ZERIX Theme to v$VERSION"
  install_theme
}

latest_backup(){
  if [[ -f "$BACKUP_ROOT/latest" ]]; then cat "$BACKUP_ROOT/latest"; return 0; fi
  find "$BACKUP_ROOT" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | sort | tail -n1
}

uninstall_theme(){
  require_root; validate_panel
  echo
  say "Uninstalling ZERIX Theme..."
  local latest
  latest="$(latest_backup || true)"
  if [[ -n "$latest" && -f "$latest/index.tsx" ]]; then
    cp -a "$latest/index.tsx" "$INDEX"
    ok "Original frontend index restored from backup."
  else
    remove_imports
    warn "No ZERIX backup found; removed ZERIX imports instead."
  fi
  rm -rf "$THEME_DIR"
  rm -f "$PANEL/public/assets/zerix-icon.svg" "$PANEL/public/assets/zerix-theme.json"
  build_panel
  ok "ZERIX Theme uninstalled successfully."
}

main(){
  require_root
  while true; do
    banner
    read -r -p "  Select an option [0-3]: " choice
    case "$choice" in
      1) install_theme; read -r -p $'\n  Press Enter to return to menu...' _ ;;
      2) uninstall_theme; read -r -p $'\n  Press Enter to return to menu...' _ ;;
      3) update_theme; read -r -p $'\n  Press Enter to return to menu...' _ ;;
      0) echo; say "Goodbye."; exit 0 ;;
      *) warn "Invalid option. Please choose 0, 1, 2 or 3."; sleep 1 ;;
    esac
  done
}

main "$@"
