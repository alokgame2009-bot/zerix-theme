#!/usr/bin/env bash
set -Eeuo pipefail

VERSION="1.3.2"
PANEL="${ZERIX_PANEL_PATH:-/var/www/pterodactyl}"
REPO_RAW_BASE="${ZERIX_REPO_RAW_BASE:-https://raw.githubusercontent.com/alokgame2009-bot/zerix-theme/main}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOCAL_RESOURCES="$SCRIPT_DIR/resources"
INDEX="$PANEL/resources/scripts/index.tsx"
THEME_DIR="$PANEL/resources/scripts/Zerix"
STATE_DIR="$PANEL/storage/zerix-theme"
STATE_FILE="$STATE_DIR/installed"
BACKUP_ROOT="$PANEL/storage/zerix-theme-backup"
TMP_DIR=""
RESOURCE_DIR=""

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'

say(){ printf "${CYAN}[ZERIX]${NC} %s\n" "$*"; }
ok(){ printf "${GREEN}[  OK  ]${NC} %s\n" "$*"; }
warn(){ printf "${YELLOW}[ WARN ]${NC} %s\n" "$*"; }
die(){ printf "${RED}[ ERROR]${NC} %s\n" "$*" >&2; return 1; }

cleanup(){ [[ -n "${TMP_DIR:-}" && -d "$TMP_DIR" ]] && rm -rf "$TMP_DIR" || true; }
trap cleanup EXIT

banner(){
  clear 2>/dev/null || true
  printf '\n                 ZERIX\n                  THEME\n'
  printf '        Zerix Theme Installer\n        Power by SkylerNodes\n        Made by Zyren\n        Version %s\n\n' "$VERSION"
  printf '  ────────────────────────────────────────────────\n'
  printf '    [1]  Zerix Theme Install\n    [2]  Theme Uninstall\n    [3]  Theme Update\n    [0]  Exit\n'
  printf '  ────────────────────────────────────────────────\n\n'
}

require_root(){ [[ $EUID -eq 0 ]] || { die "Run as root: sudo bash zerix.sh"; exit 1; }; }

require_commands(){
  local c
  for c in curl sed cp mktemp grep find sort date; do
    command -v "$c" >/dev/null 2>&1 || { die "Required command missing: $c"; return 1; }
  done
}

validate_panel(){
  [[ -d "$PANEL" ]] || { die "Pterodactyl directory not found: $PANEL"; return 1; }
  [[ -f "$INDEX" ]] || { die "Frontend index not found: $INDEX"; return 1; }
  [[ -f "$PANEL/package.json" ]] || { die "package.json not found: $PANEL/package.json"; return 1; }
}

download_file(){
  curl -fL --silent --show-error \
    --connect-timeout 10 --max-time 120 --retry 4 --retry-delay 2 \
    "$1" -o "$2"
}

load_resources(){
  if [[ -d "$LOCAL_RESOURCES/scripts/Zerix" ]]; then
    RESOURCE_DIR="$LOCAL_RESOURCES"
    say "Using local ZERIX resources."
    return 0
  fi

  [[ "$REPO_RAW_BASE" != *YOUR_USERNAME* && "$REPO_RAW_BASE" != *YOUR_REPOSITORY* ]] || {
    die "Invalid GitHub repository URL: $REPO_RAW_BASE"; return 1;
  }

  TMP_DIR="$(mktemp -d -t zerix.XXXXXX)"
  RESOURCE_DIR="$TMP_DIR/resources"
  mkdir -p "$RESOURCE_DIR/scripts/Zerix/assets"

  say "Downloading ZERIX files..."
  download_file "$REPO_RAW_BASE/resources/scripts/Zerix/main.css" "$RESOURCE_DIR/scripts/Zerix/main.css" & p1=$!
  download_file "$REPO_RAW_BASE/resources/scripts/Zerix/theme.ts" "$RESOURCE_DIR/scripts/Zerix/theme.ts" & p2=$!
  download_file "$REPO_RAW_BASE/resources/scripts/Zerix/assets/zerix-icon.svg" "$RESOURCE_DIR/scripts/Zerix/assets/zerix-icon.svg" & p3=$!
  download_file "$REPO_RAW_BASE/resources/scripts/Zerix/assets/theme.json" "$RESOURCE_DIR/scripts/Zerix/assets/theme.json" & p4=$!

  local failed=0
  wait "$p1" || failed=1
  wait "$p2" || failed=1
  wait "$p3" || failed=1
  wait "$p4" || failed=1
  (( failed == 0 )) || { die "GitHub download failed. Check the repository files/URL."; return 1; }

  for f in main.css theme.ts assets/zerix-icon.svg assets/theme.json; do
    [[ -s "$RESOURCE_DIR/scripts/Zerix/$f" ]] || { die "Downloaded file is missing/empty: $f"; return 1; }
  done
  ok "ZERIX files downloaded."
}

is_installed(){
  [[ -f "$STATE_FILE" ]] && grep -q '^installed=1$' "$STATE_FILE" 2>/dev/null
}

has_zerix_content(){
  [[ -d "$THEME_DIR" ]] || grep -Fq "./Zerix/main.css" "$INDEX" 2>/dev/null || grep -Fq "./Zerix/theme.ts" "$INDEX" 2>/dev/null
}

create_backup(){
  local stamp backup
  stamp="$(date +%Y%m%d-%H%M%S)"
  backup="$BACKUP_ROOT/$stamp"
  mkdir -p "$backup"
  cp -a "$INDEX" "$backup/index.tsx"
  [[ -d "$THEME_DIR" ]] && cp -a "$THEME_DIR" "$backup/Zerix" || true
  [[ -f "$PANEL/public/assets/zerix-icon.svg" ]] && cp -a "$PANEL/public/assets/zerix-icon.svg" "$backup/zerix-icon.svg" || true
  [[ -f "$PANEL/public/assets/zerix-theme.json" ]] && cp -a "$PANEL/public/assets/zerix-theme.json" "$backup/zerix-theme.json" || true
  mkdir -p "$BACKUP_ROOT"
  printf '%s\n' "$backup" > "$BACKUP_ROOT/latest"
  BACKUP="$backup"
  say "Backup created: $BACKUP"
}

restore_backup(){
  local backup="$1"
  [[ -f "$backup/index.tsx" ]] || return 1
  cp -a "$backup/index.tsx" "$INDEX"
  rm -rf "$THEME_DIR"
  rm -f "$PANEL/public/assets/zerix-icon.svg" "$PANEL/public/assets/zerix-theme.json"
  [[ -d "$backup/Zerix" ]] && cp -a "$backup/Zerix" "$THEME_DIR"
  [[ -f "$backup/zerix-icon.svg" ]] && cp -a "$backup/zerix-icon.svg" "$PANEL/public/assets/zerix-icon.svg"
  [[ -f "$backup/zerix-theme.json" ]] && cp -a "$backup/zerix-theme.json" "$PANEL/public/assets/zerix-theme.json"
  ok "Backup restored."
}

add_imports(){
  local css="import './Zerix/main.css';"
  local ts="import './Zerix/theme.ts';"
  grep -Fqx "$css" "$INDEX" || sed -i "1i $css" "$INDEX"
  grep -Fqx "$ts" "$INDEX" || sed -i "2i $ts" "$INDEX"
}

remove_imports(){
  sed -i "/^[[:space:]]*import ['\"]\.\/Zerix\/main\.css['\"];[[:space:]]*$/d" "$INDEX" || true
  sed -i "/^[[:space:]]*import ['\"]\.\/Zerix\/theme\.ts['\"];[[:space:]]*$/d" "$INDEX" || true
}

build_panel(){
  cd "$PANEL"
  export CI=1

  # Older Pterodactyl/Blueprint webpack stacks use hashing code that is
  # incompatible with OpenSSL 3 used by newer Node.js versions. This
  # compatibility flag fixes ERR_OSSL_EVP_UNSUPPORTED / 0308010C.
  export NODE_OPTIONS="--openssl-legacy-provider${NODE_OPTIONS:+ $NODE_OPTIONS}"

  local build_status=0

  if command -v yarn >/dev/null 2>&1 && [[ -f yarn.lock ]]; then
    say "Building frontend with Yarn..."
    timeout --signal=TERM --kill-after=30s 45m yarn build:production || build_status=$?
  elif command -v npm >/dev/null 2>&1 && [[ -f package.json ]]; then
    say "Building frontend with npm..."
    timeout --signal=TERM --kill-after=30s 45m npm run build:production || build_status=$?
  else
    die "No Yarn/npm build environment found."
  fi

  # Never report success when webpack failed.
  if [[ "$build_status" -ne 0 ]]; then
    if [[ "$build_status" -eq 124 || "$build_status" -eq 137 || "$build_status" -eq 143 ]]; then
      warn "Frontend build timed out or was terminated (exit $build_status)."
    else
      warn "Frontend build failed (exit $build_status)."
    fi
    return "$build_status"
  fi

  if command -v php >/dev/null 2>&1 && [[ -f "$PANEL/artisan" ]]; then
    php artisan view:clear >/dev/null 2>&1 || true
  fi

  return 0
}

write_state(){
  mkdir -p "$STATE_DIR"
  printf 'installed=1\nversion=%s\ninstalled_at=%s\n' "$VERSION" "$(date '+%Y-%m-%d %H:%M:%S')" > "$STATE_FILE"
}

install_theme(){
  require_root; require_commands; validate_panel; load_resources
  echo
  say "Installing/repairing ZERIX Theme v$VERSION"
  if command -v node >/dev/null 2>&1; then
    say "Node.js: $(node --version)"
  fi
  create_backup

  # A previous failed install may have left partial files. Replace only ZERIX-owned files.
  mkdir -p "$THEME_DIR" "$PANEL/public/assets"
  cp -a "$RESOURCE_DIR/scripts/Zerix/." "$THEME_DIR/"
  cp -f "$RESOURCE_DIR/scripts/Zerix/assets/zerix-icon.svg" "$PANEL/public/assets/zerix-icon.svg"
  cp -f "$RESOURCE_DIR/scripts/Zerix/assets/theme.json" "$PANEL/public/assets/zerix-theme.json"
  add_imports

  if ! build_panel; then
    warn "Frontend build failed or timed out. Rolling back..."
    restore_backup "$BACKUP" || true
    return 1
  fi

  write_state
  ok "ZERIX Theme installed successfully."
  ok "Backup: $BACKUP"
}

update_theme(){
  require_root; require_commands; validate_panel; load_resources
  echo
  say "Updating ZERIX Theme to v$VERSION"
  if command -v node >/dev/null 2>&1; then
    say "Node.js: $(node --version)"
  fi
  create_backup

  mkdir -p "$THEME_DIR" "$PANEL/public/assets"
  cp -a "$RESOURCE_DIR/scripts/Zerix/." "$THEME_DIR/"
  cp -f "$RESOURCE_DIR/scripts/Zerix/assets/zerix-icon.svg" "$PANEL/public/assets/zerix-icon.svg"
  cp -f "$RESOURCE_DIR/scripts/Zerix/assets/theme.json" "$PANEL/public/assets/zerix-theme.json"
  add_imports

  if ! build_panel; then
    warn "Frontend build failed or timed out. Rolling back..."
    restore_backup "$BACKUP" || true
    return 1
  fi

  write_state
  ok "ZERIX Theme updated successfully."
  ok "Backup: $BACKUP"
}

latest_backup(){
  [[ -f "$BACKUP_ROOT/latest" ]] && { cat "$BACKUP_ROOT/latest"; return 0; }
  find "$BACKUP_ROOT" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | sort | tail -n1
}

uninstall_theme(){
  require_root; require_commands; validate_panel
  echo
  say "Uninstalling ZERIX Theme..."

  # Do NOT blindly restore an arbitrary backup. Remove only ZERIX changes.
  remove_imports
  rm -rf "$THEME_DIR"
  rm -f "$PANEL/public/assets/zerix-icon.svg" "$PANEL/public/assets/zerix-theme.json"
  rm -f "$STATE_FILE"

  if ! build_panel; then
    warn "Uninstall build failed. Your original index is still backed up under: $BACKUP_ROOT"
    return 1
  fi
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
        if is_installed; then
          warn "ZERIX is already installed. Starting repair/reinstall instead."
        elif has_zerix_content; then
          warn "Partial ZERIX files detected. Repairing installation..."
        fi
        install_theme || true
        read -r -p $'\n  Press Enter to return to menu...' _
        ;;
      2)
        uninstall_theme || true
        read -r -p $'\n  Press Enter to return to menu...' _
        ;;
      3)
        update_theme || true
        read -r -p $'\n  Press Enter to return to menu...' _
        ;;
      0)
        echo; say "Goodbye."; exit 0
        ;;
      *)
        warn "Invalid option. Please choose 0, 1, 2 or 3."; sleep 1
        ;;
    esac
  done
}

main "$@"
