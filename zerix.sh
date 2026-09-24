#!/usr/bin/env bash
set -Eeuo pipefail

# ============================================================
# ZERIX THEME INSTALLER
# Power by SkylerNodes | Made by Zyren
# ============================================================

VERSION="1.2.0"
PANEL="${ZERIX_PANEL_PATH:-/var/www/pterodactyl}"

# GitHub repository
REPO_RAW_BASE="https://raw.githubusercontent.com/alokgame2009-bot/zerix-theme/main"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd || true)"
LOCAL_RESOURCES="$SCRIPT_DIR/resources"
TMP_DIR=""
STAMP="$(date +%Y%m%d-%H%M%S)"

BACKUP_ROOT="$PANEL/storage/zerix-theme-backup"
BACKUP="$BACKUP_ROOT/$STAMP"
STATE_FILE="$BACKUP_ROOT/state"

INDEX="$PANEL/resources/scripts/index.tsx"
THEME_DIR="$PANEL/resources/scripts/Zerix"
PUBLIC_ASSETS="$PANEL/public/assets"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BLUE='\033[0;34m'
NC='\033[0m'

say(){ printf "${CYAN}[ZERIX]${NC} %s\n" "$*"; }
ok(){ printf "${GREEN}[  OK  ]${NC} %s\n" "$*"; }
warn(){ printf "${YELLOW}[ WARN ]${NC} %s\n" "$*"; }
die(){ printf "${RED}[ ERROR]${NC} %s\n" "$*" >&2; exit 1; }

cleanup(){
  [[ -n "${TMP_DIR:-}" && -d "$TMP_DIR" ]] && rm -rf "$TMP_DIR"
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
  local missing=()
  command -v curl >/dev/null 2>&1 || missing+=("curl")

  if ((${#missing[@]})); then
    die "Missing required command(s): ${missing[*]}. Install them and run again."
  fi
}

validate_panel(){
  [[ -d "$PANEL" ]] || die "Pterodactyl directory not found: $PANEL"
  [[ -f "$INDEX" ]] || die "Frontend index not found: $INDEX"
  [[ -f "$PANEL/package.json" ]] || die "Pterodactyl package.json not found: $PANEL/package.json"
}

confirm(){
  local answer
  read -r -p "  Continue? [y/N]: " answer
  [[ "$answer" =~ ^[Yy]$ ]]
}

load_resources(){
  if [[ -d "$LOCAL_RESOURCES/scripts/Zerix" ]]; then
    RESOURCE_DIR="$LOCAL_RESOURCES"
    say "Using local ZERIX resources."
    return
  fi

  [[ "$REPO_RAW_BASE" == https://raw.githubusercontent.com/* ]] ||
    die "Invalid REPO_RAW_BASE."

  TMP_DIR="$(mktemp -d)"
  say "Downloading ZERIX files from GitHub..."

  mkdir -p "$TMP_DIR/resources/scripts/Zerix/assets"

  # Download all 4 small files in parallel.
  curl -fsSL --retry 2 --connect-timeout 5 "$REPO_RAW_BASE/resources/scripts/Zerix/main.css" -o "$TMP_DIR/resources/scripts/Zerix/main.css" &
  curl -fsSL --retry 2 --connect-timeout 5 "$REPO_RAW_BASE/resources/scripts/Zerix/theme.ts" -o "$TMP_DIR/resources/scripts/Zerix/theme.ts" &
  curl -fsSL --retry 2 --connect-timeout 5 "$REPO_RAW_BASE/resources/scripts/Zerix/assets/zerix-icon.svg" -o "$TMP_DIR/resources/scripts/Zerix/assets/zerix-icon.svg" &
  curl -fsSL --retry 2 --connect-timeout 5 "$REPO_RAW_BASE/resources/scripts/Zerix/assets/theme.json" -o "$TMP_DIR/resources/scripts/Zerix/assets/theme.json" &
  wait

  RESOURCE_DIR="$TMP_DIR/resources"
  ok "ZERIX resources downloaded."
}

create_backup(){
  mkdir -p "$BACKUP_ROOT" "$BACKUP"

  cp -a "$INDEX" "$BACKUP/index.tsx"

  # Keep the backup focused on files this installer changes.
  if [[ -d "$THEME_DIR" ]]; then
    cp -a "$THEME_DIR" "$BACKUP/Zerix"
  fi

  if [[ -f "$PUBLIC_ASSETS/zerix-icon.svg" ]]; then
    cp -a "$PUBLIC_ASSETS/zerix-icon.svg" "$BACKUP/zerix-icon.svg"
  fi

  if [[ -f "$PUBLIC_ASSETS/zerix-theme.json" ]]; then
    cp -a "$PUBLIC_ASSETS/zerix-theme.json" "$BACKUP/zerix-theme.json"
  fi

  printf '%s\n' "$BACKUP" > "$BACKUP_ROOT/latest"
  ok "Backup created: $BACKUP"
}

save_state(){
  mkdir -p "$BACKUP_ROOT"

  cat > "$STATE_FILE" <<EOF
VERSION=$VERSION
PANEL=$PANEL
INDEX=$INDEX
THEME_DIR=$THEME_DIR
BACKUP=$BACKUP
INSTALLED_AT=$(date -Is)
EOF
}

add_imports(){
  local css="import './Zerix/main.css';"
  local ts="import './Zerix/theme.ts';"

  if ! grep -Fqx "$css" "$INDEX"; then
    sed -i "1i $css" "$INDEX"
  fi

  if ! grep -Fqx "$ts" "$INDEX"; then
    sed -i "2i $ts" "$INDEX"
  fi
}

remove_imports(){
  sed -i \
    -e "/^import ['\"]\.\/Zerix\/main\.css['\"];$/d" \
    -e "/^import ['\"]\.\/Zerix\/theme\.ts['\"];$/d" \
    "$INDEX" || true
}

install_files(){
  mkdir -p "$THEME_DIR" "$PUBLIC_ASSETS"

  rm -rf "$THEME_DIR"
  mkdir -p "$THEME_DIR"

  cp -a "$RESOURCE_DIR/scripts/Zerix/." "$THEME_DIR/"

  cp -f \
    "$RESOURCE_DIR/scripts/Zerix/assets/zerix-icon.svg" \
    "$PUBLIC_ASSETS/zerix-icon.svg"

  cp -f \
    "$RESOURCE_DIR/scripts/Zerix/assets/theme.json" \
    "$PUBLIC_ASSETS/zerix-theme.json"
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
    die "Neither Yarn nor npm build environment was found."
  fi

  # Clear only the frontend/view cache needed after the build.
  if command -v php >/dev/null 2>&1 && [[ -f artisan ]]; then
    php artisan view:clear >/dev/null 2>&1 || true
  fi
}

install_theme(){
  require_root
  require_commands
  validate_panel

  echo
  say "Installing ZERIX Theme v$VERSION"
  echo

  if [[ -f "$STATE_FILE" ]]; then
    warn "ZERIX appears to be already installed."
    warn "Use [3] Theme Update instead of installing again."
    return 1
  fi

  load_resources
  create_backup

  install_files
  add_imports

  say "Building Pterodactyl frontend..."
  if ! build_panel; then
    warn "Build failed. Restoring the pre-install backup..."
    cp -a "$BACKUP/index.tsx" "$INDEX"
    rm -rf "$THEME_DIR"
    [[ -f "$BACKUP/zerix-icon.svg" ]] && cp -a "$BACKUP/zerix-icon.svg" "$PUBLIC_ASSETS/zerix-icon.svg" || rm -f "$PUBLIC_ASSETS/zerix-icon.svg"
    [[ -f "$BACKUP/zerix-theme.json" ]] && cp -a "$BACKUP/zerix-theme.json" "$PUBLIC_ASSETS/zerix-theme.json" || rm -f "$PUBLIC_ASSETS/zerix-theme.json"
    exit 1
  fi

  save_state

  echo
  ok "ZERIX Theme installed successfully."
  ok "Backup: $BACKUP"
}

update_theme(){
  require_root
  require_commands
  validate_panel

  echo
  say "Updating ZERIX Theme to v$VERSION"
  echo

  load_resources

  # Update gets its own backup so rollback is possible.
  create_backup
  install_files
  add_imports

  say "Building Pterodactyl frontend..."
  if ! build_panel; then
    warn "Update failed. Restoring the previous frontend files..."

    cp -a "$BACKUP/index.tsx" "$INDEX"
    rm -rf "$THEME_DIR"

    if [[ -d "$BACKUP/Zerix" ]]; then
      cp -a "$BACKUP/Zerix" "$THEME_DIR"
    fi

    if [[ -f "$BACKUP/zerix-icon.svg" ]]; then
      cp -a "$BACKUP/zerix-icon.svg" "$PUBLIC_ASSETS/zerix-icon.svg"
    fi

    if [[ -f "$BACKUP/zerix-theme.json" ]]; then
      cp -a "$BACKUP/zerix-theme.json" "$PUBLIC_ASSETS/zerix-theme.json"
    fi

    exit 1
  fi

  save_state

  echo
  ok "ZERIX Theme updated successfully."
  ok "Backup: $BACKUP"
}

uninstall_theme(){
  require_root
  require_commands
  validate_panel

  echo
  say "Uninstalling ZERIX Theme..."
  echo

  if [[ ! -f "$STATE_FILE" ]]; then
    warn "ZERIX installation state was not found."
    warn "The installer will only remove ZERIX files/imports."
  fi

  if ! confirm; then
    warn "Uninstall cancelled."
    return 0
  fi

  # Only remove the imports that this installer added.
  remove_imports

  rm -rf "$THEME_DIR"
  rm -f \
    "$PUBLIC_ASSETS/zerix-icon.svg" \
    "$PUBLIC_ASSETS/zerix-theme.json"

  say "Building Pterodactyl frontend..."
  build_panel

  rm -f "$STATE_FILE"

  echo
  ok "ZERIX Theme uninstalled successfully."
}

main(){
  require_root
  require_commands

  while true; do
    banner

    read -r -p "  Select an option [0-3]: " choice
    echo

    case "$choice" in
      1)
        if install_theme; then
          read -r -p $'\n  Press Enter to return to menu...' _
        else
          read -r -p $'\n  Press Enter to return to menu...' _
        fi
        ;;

      2)
        if uninstall_theme; then
          read -r -p $'\n  Press Enter to return to menu...' _
        else
          read -r -p $'\n  Press Enter to return to menu...' _
        fi
        ;;

      3)
        if update_theme; then
          read -r -p $'\n  Press Enter to return to menu...' _
        else
          read -r -p $'\n  Press Enter to return to menu...' _
        fi
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
