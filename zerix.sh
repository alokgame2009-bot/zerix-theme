#!/usr/bin/env bash
set -Eeuo pipefail

# ============================================================
# ZERIX THEME INSTALLER
# Ubuntu 24.04 / Pterodactyl compatible
# Power by SkylerNodes | Made by Zyren
# ============================================================

VERSION="1.2.1"
PANEL="${ZERIX_PANEL_PATH:-/var/www/pterodactyl}"
REPO_RAW_BASE="${ZERIX_REPO_RAW_BASE:-https://raw.githubusercontent.com/alokgame2009-bot/zerix-theme/main}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOCAL_RESOURCES="$SCRIPT_DIR/resources"
INDEX="$PANEL/resources/scripts/index.tsx"
THEME_DIR="$PANEL/resources/scripts/Zerix"
BACKUP_ROOT="$PANEL/storage/zerix-theme-backup"
STAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP="$BACKUP_ROOT/$STAMP"
TMP_DIR=""

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

say(){ printf "${CYAN}[ZERIX]${NC} %s\n" "$*"; }
ok(){ printf "${GREEN}[  OK  ]${NC} %s\n" "$*"; }
warn(){ printf "${YELLOW}[ WARN ]${NC} %s\n" "$*"; }
die(){ printf "${RED}[ ERROR]${NC} %s\n" "$*" >&2; exit 1; }

cleanup() {
  if [[ -n "${TMP_DIR:-}" && -d "$TMP_DIR" ]]; then
    rm -rf "$TMP_DIR"
  fi
}
trap cleanup EXIT

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

require_root(){
  [[ $EUID -eq 0 ]] || die "Run as root: sudo bash zerix.sh"
}

require_commands(){
  command -v curl >/dev/null 2>&1 || die "curl is required. Install with: apt update && apt install -y curl"
  command -v sed >/dev/null 2>&1 || die "sed is required."
  command -v cp >/dev/null 2>&1 || die "cp is required."
}

validate_panel(){
  [[ -d "$PANEL" ]] || die "Pterodactyl directory not found: $PANEL"
  [[ -f "$INDEX" ]] || die "Frontend index not found: $INDEX"
  [[ -f "$PANEL/package.json" ]] || die "package.json not found: $PANEL/package.json"
}

download_file(){
  local url="$1"
  local out="$2"
  curl -fL --silent --show-error \
    --connect-timeout 10 \
    --max-time 90 \
    --retry 3 \
    --retry-delay 1 \
    "$url" -o "$out"
}

load_resources(){
  if [[ -d "$LOCAL_RESOURCES/scripts/Zerix" ]]; then
    RESOURCE_DIR="$LOCAL_RESOURCES"
    say "Using local ZERIX resources."
    return 0
  fi

  [[ "$REPO_RAW_BASE" != *YOUR_USERNAME* ]] || \
    die "Invalid GitHub URL. REPO_RAW_BASE still contains YOUR_USERNAME."

  TMP_DIR="$(mktemp -d -t zerix.XXXXXX)"
  RESOURCE_DIR="$TMP_DIR/resources"

  mkdir -p "$RESOURCE_DIR/scripts/Zerix/assets"

  say "Downloading ZERIX files..."

  download_file "$REPO_RAW_BASE/resources/scripts/Zerix/main.css" \
    "$RESOURCE_DIR/scripts/Zerix/main.css" &
  p1=$!

  download_file "$REPO_RAW_BASE/resources/scripts/Zerix/theme.ts" \
    "$RESOURCE_DIR/scripts/Zerix/theme.ts" &
  p2=$!

  download_file "$REPO_RAW_BASE/resources/scripts/Zerix/assets/zerix-icon.svg" \
    "$RESOURCE_DIR/scripts/Zerix/assets/zerix-icon.svg" &
  p3=$!

  download_file "$REPO_RAW_BASE/resources/scripts/Zerix/assets/theme.json" \
    "$RESOURCE_DIR/scripts/Zerix/assets/theme.json" &
  p4=$!

  local failed=0
  wait "$p1" || failed=1
  wait "$p2" || failed=1
  wait "$p3" || failed=1
  wait "$p4" || failed=1

  [[ "$failed" -eq 0 ]] || die "Failed to download one or more ZERIX files from GitHub."

  [[ -s "$RESOURCE_DIR/scripts/Zerix/main.css" ]] || die "main.css download is empty."
  [[ -s "$RESOURCE_DIR/scripts/Zerix/theme.ts" ]] || die "theme.ts download is empty."
  [[ -s "$RESOURCE_DIR/scripts/Zerix/assets/zerix-icon.svg" ]] || die "zerix-icon.svg download is empty."
  [[ -s "$RESOURCE_DIR/scripts/Zerix/assets/theme.json" ]] || die "theme.json download is empty."

  ok "ZERIX files downloaded."
}

backup_current(){
  mkdir -p "$BACKUP"

  cp -a "$INDEX" "$BACKUP/index.tsx"

  if [[ -d "$THEME_DIR" ]]; then
    cp -a "$THEME_DIR" "$BACKUP/Zerix"
  fi

  if [[ -f "$PANEL/public/assets/zerix-icon.svg" ]]; then
    cp -a "$PANEL/public/assets/zerix-icon.svg" "$BACKUP/zerix-icon.svg"
  fi

  if [[ -f "$PANEL/public/assets/zerix-theme.json" ]]; then
    cp -a "$PANEL/public/assets/zerix-theme.json" "$BACKUP/zerix-theme.json"
  fi

  mkdir -p "$BACKUP_ROOT"
  printf '%s\n' "$BACKUP" > "$BACKUP_ROOT/latest"

  say "Backup created: $BACKUP"
}

add_imports(){
  local css="import './Zerix/main.css';"
  local ts="import './Zerix/theme.ts';"

  grep -Fqx "$css" "$INDEX" || sed -i "1i $css" "$INDEX"
  grep -Fqx "$ts" "$INDEX" || sed -i "2i $ts" "$INDEX"
}

remove_imports(){
  sed -i "/^import ['\"]\.\/Zerix\/main\.css['\"];[[:space:]]*$/d" "$INDEX" || true
  sed -i "/^import ['\"]\.\/Zerix\/theme\.ts['\"];[[:space:]]*$/d" "$INDEX" || true
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

  # Only clear Laravel view cache if PHP + artisan are available.
  # No config/cache clear is needed for a CSS/TS theme.
  if command -v php >/dev/null 2>&1 && [[ -f "$PANEL/artisan" ]]; then
    php artisan view:clear >/dev/null 2>&1 || true
  fi
}

install_theme(){
  require_root
  require_commands
  validate_panel
  load_resources

  echo
  say "Installing ZERIX Theme v$VERSION"
  backup_current

  mkdir -p "$THEME_DIR"
  cp -a "$RESOURCE_DIR/scripts/Zerix/." "$THEME_DIR/"

  mkdir -p "$PANEL/public/assets"
  cp -f "$RESOURCE_DIR/scripts/Zerix/assets/zerix-icon.svg" \
    "$PANEL/public/assets/zerix-icon.svg"
  cp -f "$RESOURCE_DIR/scripts/Zerix/assets/theme.json" \
    "$PANEL/public/assets/zerix-theme.json"

  add_imports
  build_panel

  ok "ZERIX Theme installed successfully."
  ok "Backup: $BACKUP"
}

update_theme(){
  require_root
  require_commands
  validate_panel
  load_resources

  echo
  say "Updating ZERIX Theme to v$VERSION"
  backup_current

  mkdir -p "$THEME_DIR"
  cp -a "$RESOURCE_DIR/scripts/Zerix/." "$THEME_DIR/"

  mkdir -p "$PANEL/public/assets"
  cp -f "$RESOURCE_DIR/scripts/Zerix/assets/zerix-icon.svg" \
    "$PANEL/public/assets/zerix-icon.svg"
  cp -f "$RESOURCE_DIR/scripts/Zerix/assets/theme.json" \
    "$PANEL/public/assets/zerix-theme.json"

  add_imports
  build_panel

  ok "ZERIX Theme updated successfully."
  ok "Backup: $BACKUP"
}

latest_backup(){
  if [[ -f "$BACKUP_ROOT/latest" ]]; then
    cat "$BACKUP_ROOT/latest"
    return 0
  fi

  find "$BACKUP_ROOT" -mindepth 1 -maxdepth 1 -type d \
    2>/dev/null | sort | tail -n1
}

uninstall_theme(){
  require_root
  require_commands
  validate_panel

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
  rm -f "$PANEL/public/assets/zerix-icon.svg"
  rm -f "$PANEL/public/assets/zerix-theme.json"

  build_panel

  ok "ZERIX Theme uninstalled successfully."
}

main(){
  require_root
  require_commands

  while true; do
    banner

    read -r -p "  Select an option [0-3]: " choice

    case "$choice" in
      1)
        install_theme
        read -r -p $'\n  Press Enter to return to menu...' _
        ;;
      2)
        uninstall_theme
        read -r -p $'\n  Press Enter to return to menu...' _
        ;;
      3)
        update_theme
        read -r -p $'\n  Press Enter to return to menu...' _
        ;;
      0)
        echo
        say "Goodbye."
        exit 0
        ;;
      *)
        warn "Invalid option. Please choose 0, 1, 2 or 3."
        sleep 1
        ;;
    esac
  done
}

main "$@"
