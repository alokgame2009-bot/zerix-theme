#!/usr/bin/env bash
set -Eeuo pipefail

# ============================================================
# ZERIX THEME INSTALLER
# Ubuntu 22.04 / 24.04 + Pterodactyl compatible
# Power by SkylerNodes | Made by Zyren
# ============================================================

VERSION="1.3.0"
PANEL="${ZERIX_PANEL_PATH:-/var/www/pterodactyl}"
REPO_RAW_BASE="${ZERIX_REPO_RAW_BASE:-https://raw.githubusercontent.com/alokgame2009-bot/zerix-theme/main}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd || true)"
LOCAL_RESOURCES="${SCRIPT_DIR}/resources"
INDEX="${PANEL}/resources/scripts/index.tsx"
THEME_DIR="${PANEL}/resources/scripts/Zerix"
BACKUP_ROOT="${PANEL}/storage/zerix-theme-backup"
STAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP="${BACKUP_ROOT}/${STAMP}"
TMP_DIR=""
RESOURCE_DIR=""
STATE_DIR="${PANEL}/storage/zerix-theme"
STATE_FILE="${STATE_DIR}/installed"
BUILD_TIMEOUT="${ZERIX_BUILD_TIMEOUT:-45m}"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'

say(){ printf "${CYAN}[ZERIX]${NC} %s\n" "$*"; }
ok(){ printf "${GREEN}[  OK  ]${NC} %s\n" "$*"; }
warn(){ printf "${YELLOW}[ WARN ]${NC} %s\n" "$*"; }
die(){ printf "${RED}[ ERROR]${NC} %s\n" "$*" >&2; exit 1; }

cleanup(){
    if [[ -n "${TMP_DIR:-}" && -d "${TMP_DIR}" ]]; then
        rm -rf "${TMP_DIR}"
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
    printf '        Version %s\n' "${VERSION}"
    printf '\n'
    printf '  ────────────────────────────────────────────────\n'
    printf '    [1]  Zerix Theme Install\n'
    printf '    [2]  Theme Uninstall\n'
    printf '    [3]  Theme Update\n'
    printf '    [0]  Exit\n'
    printf '  ────────────────────────────────────────────────\n\n'
}

require_root(){
    [[ "${EUID}" -eq 0 ]] || die "Run as root: sudo bash zerix.sh"
}

require_commands(){
    local cmd
    for cmd in curl sed cp grep mktemp date find sort tail timeout; do
        command -v "${cmd}" >/dev/null 2>&1 || die "${cmd} is required. Install with: apt update && apt install -y ${cmd}"
    done
}

check_os(){
    if [[ -r /etc/os-release ]]; then
        # shellcheck disable=SC1091
        . /etc/os-release

        if [[ "${ID:-}" != "ubuntu" ]]; then
            warn "Detected OS: ${PRETTY_NAME:-unknown}"
            warn "This installer is tested for Ubuntu 22.04 and 24.04."
        elif [[ "${VERSION_ID:-}" != "22.04" && "${VERSION_ID:-}" != "24.04" ]]; then
            warn "Detected Ubuntu ${VERSION_ID:-unknown}. Supported targets are Ubuntu 22.04 and 24.04."
        else
            say "Detected ${PRETTY_NAME}."
        fi
    fi
}

validate_panel(){
    [[ -d "${PANEL}" ]] || die "Pterodactyl directory not found: ${PANEL}"
    [[ -f "${INDEX}" ]] || die "Frontend index not found: ${INDEX}"
    [[ -f "${PANEL}/package.json" ]] || die "package.json not found: ${PANEL}/package.json"

    if [[ ! -d "${PANEL}/resources/scripts" ]]; then
        die "Pterodactyl frontend resources/scripts directory not found."
    fi
}

download_file(){
    local url="$1"
    local out="$2"

    curl -fL --silent --show-error \
        --connect-timeout 10 \
        --max-time 120 \
        --retry 4 \
        --retry-delay 2 \
        --retry-all-errors \
        "${url}" -o "${out}"
}

load_resources(){
    if [[ -d "${LOCAL_RESOURCES}/scripts/Zerix" ]] &&
       [[ -f "${LOCAL_RESOURCES}/scripts/Zerix/main.css" ]] &&
       [[ -f "${LOCAL_RESOURCES}/scripts/Zerix/theme.ts" ]]; then

        RESOURCE_DIR="${LOCAL_RESOURCES}"
        say "Using local ZERIX resources."
        return 0
    fi

    if [[ "${REPO_RAW_BASE}" == *YOUR_USERNAME* ||
          "${REPO_RAW_BASE}" == *YOUR_REPOSITORY* ]]; then
        die "GitHub URL is still using a placeholder. Expected: ${REPO_RAW_BASE}"
    fi

    TMP_DIR="$(mktemp -d -t zerix.XXXXXX)"
    RESOURCE_DIR="${TMP_DIR}/resources"

    mkdir -p "${RESOURCE_DIR}/scripts/Zerix/assets"

    say "Downloading ZERIX files from GitHub..."

    download_file \
        "${REPO_RAW_BASE}/resources/scripts/Zerix/main.css" \
        "${RESOURCE_DIR}/scripts/Zerix/main.css" &
    local p1=$!

    download_file \
        "${REPO_RAW_BASE}/resources/scripts/Zerix/theme.ts" \
        "${RESOURCE_DIR}/scripts/Zerix/theme.ts" &
    local p2=$!

    download_file \
        "${REPO_RAW_BASE}/resources/scripts/Zerix/assets/zerix-icon.svg" \
        "${RESOURCE_DIR}/scripts/Zerix/assets/zerix-icon.svg" &
    local p3=$!

    download_file \
        "${REPO_RAW_BASE}/resources/scripts/Zerix/assets/theme.json" \
        "${RESOURCE_DIR}/scripts/Zerix/assets/theme.json" &
    local p4=$!

    local failed=0
    wait "${p1}" || failed=1
    wait "${p2}" || failed=1
    wait "${p3}" || failed=1
    wait "${p4}" || failed=1

    [[ "${failed}" -eq 0 ]] ||
        die "Failed to download one or more ZERIX files. Check the GitHub URL and VPS internet connection."

    [[ -s "${RESOURCE_DIR}/scripts/Zerix/main.css" ]] ||
        die "main.css download is empty."

    [[ -s "${RESOURCE_DIR}/scripts/Zerix/theme.ts" ]] ||
        die "theme.ts download is empty."

    [[ -s "${RESOURCE_DIR}/scripts/Zerix/assets/zerix-icon.svg" ]] ||
        die "zerix-icon.svg download is empty."

    [[ -s "${RESOURCE_DIR}/scripts/Zerix/assets/theme.json" ]] ||
        die "theme.json download is empty."

    ok "ZERIX files downloaded."
}

backup_current(){
    mkdir -p "${BACKUP_ROOT}" "${BACKUP}"

    cp -a "${INDEX}" "${BACKUP}/index.tsx"

    if [[ -d "${THEME_DIR}" ]]; then
        cp -a "${THEME_DIR}" "${BACKUP}/Zerix"
    fi

    if [[ -f "${PANEL}/public/assets/zerix-icon.svg" ]]; then
        cp -a "${PANEL}/public/assets/zerix-icon.svg" "${BACKUP}/zerix-icon.svg"
    fi

    if [[ -f "${PANEL}/public/assets/zerix-theme.json" ]]; then
        cp -a "${PANEL}/public/assets/zerix-theme.json" "${BACKUP}/zerix-theme.json"
    fi

    printf '%s\n' "${BACKUP}" > "${BACKUP_ROOT}/latest"

    say "Backup created: ${BACKUP}"
}

restore_backup(){
    local backup="$1"

    [[ -d "${backup}" ]] || return 1
    [[ -f "${backup}/index.tsx" ]] || return 1

    cp -a "${backup}/index.tsx" "${INDEX}"

    rm -rf "${THEME_DIR}"

    if [[ -d "${backup}/Zerix" ]]; then
        cp -a "${backup}/Zerix" "${THEME_DIR}"
    fi

    mkdir -p "${PANEL}/public/assets"

    if [[ -f "${backup}/zerix-icon.svg" ]]; then
        cp -a "${backup}/zerix-icon.svg" \
            "${PANEL}/public/assets/zerix-icon.svg"
    else
        rm -f "${PANEL}/public/assets/zerix-icon.svg"
    fi

    if [[ -f "${backup}/zerix-theme.json" ]]; then
        cp -a "${backup}/zerix-theme.json" \
            "${PANEL}/public/assets/zerix-theme.json"
    else
        rm -f "${PANEL}/public/assets/zerix-theme.json"
    fi

    ok "Backup restored."
}

add_imports(){
    local css="import './Zerix/main.css';"
    local ts="import './Zerix/theme.ts';"
    local tmp_index

    tmp_index="$(mktemp)"

    {
        printf '%s\n' "${css}"
        printf '%s\n' "${ts}"
        cat "${INDEX}"
    } > "${tmp_index}"

    # Remove any old copies from the original file before replacing it.
    sed -i \
        "/^import ['\"]\.\/Zerix\/main\.css['\"];[[:space:]]*$/d" \
        "${tmp_index}"

    sed -i \
        "/^import ['\"]\.\/Zerix\/theme\.ts['\"];[[:space:]]*$/d" \
        "${tmp_index}"

    # Put both imports at the very top, exactly once.
    {
        printf '%s\n' "${css}"
        printf '%s\n' "${ts}"
        cat "${tmp_index}"
    } > "${tmp_index}.final"

    mv "${tmp_index}.final" "${INDEX}"
    rm -f "${tmp_index}"
}

remove_imports(){
    sed -i \
        "/^import ['\"]\.\/Zerix\/main\.css['\"];[[:space:]]*$/d" \
        "${INDEX}" || true

    sed -i \
        "/^import ['\"]\.\/Zerix\/theme\.ts['\"];[[:space:]]*$/d" \
        "${INDEX}" || true
}

copy_theme_files(){
    mkdir -p "${THEME_DIR}"
    cp -a "${RESOURCE_DIR}/scripts/Zerix/." "${THEME_DIR}/"

    mkdir -p "${PANEL}/public/assets"

    cp -f \
        "${RESOURCE_DIR}/scripts/Zerix/assets/zerix-icon.svg" \
        "${PANEL}/public/assets/zerix-icon.svg"

    cp -f \
        "${RESOURCE_DIR}/scripts/Zerix/assets/theme.json" \
        "${PANEL}/public/assets/zerix-theme.json"

    # Preserve the normal Pterodactyl ownership when the account exists.
    if id www-data >/dev/null 2>&1; then
        chown -R www-data:www-data "${THEME_DIR}" 2>/dev/null || true
        chown www-data:www-data \
            "${PANEL}/public/assets/zerix-icon.svg" \
            "${PANEL}/public/assets/zerix-theme.json" 2>/dev/null || true
    fi
}

build_panel(){
    cd "${PANEL}" || die "Cannot enter ${PANEL}"

    local build_status=0

    if command -v yarn >/dev/null 2>&1 && [[ -f "${PANEL}/yarn.lock" ]]; then
        say "Building frontend with Yarn..."
        say "Build timeout: ${BUILD_TIMEOUT}. The build output below is normal."
        export CI=1
        timeout --foreground "${BUILD_TIMEOUT}" \
            yarn build:production || build_status=$?
    elif command -v npm >/dev/null 2>&1 && [[ -f "${PANEL}/package.json" ]]; then
        say "Building frontend with npm..."
        say "Build timeout: ${BUILD_TIMEOUT}. The build output below is normal."
        export CI=1
        timeout --foreground "${BUILD_TIMEOUT}" \
            npm run build:production || build_status=$?
    else
        die "No Yarn/npm build environment found. Install the Node.js environment required by your Pterodactyl version first."
    fi

    if [[ "${build_status}" -eq 124 ]]; then
        die "Frontend build exceeded ${BUILD_TIMEOUT} and was stopped. The VPS may need more CPU/RAM."
    fi

    if [[ "${build_status}" -ne 0 ]]; then
        die "Frontend build failed with exit code ${build_status}."
    fi

    if command -v php >/dev/null 2>&1 && [[ -f "${PANEL}/artisan" ]]; then
        php artisan view:clear >/dev/null 2>&1 || true
    fi

    ok "Frontend build completed."
}

mark_installed(){
    mkdir -p "${STATE_DIR}"
    {
        printf 'VERSION=%s\n' "${VERSION}"
        printf 'INSTALLED_AT=%s\n' "$(date '+%Y-%m-%d %H:%M:%S')"
    } > "${STATE_FILE}"
}

is_installed(){
    [[ -f "${STATE_FILE}" ]] && return 0
    [[ -d "${THEME_DIR}" ]] && return 0

    grep -Fqx "import './Zerix/main.css';" "${INDEX}" 2>/dev/null && return 0
    grep -Fqx "import './Zerix/theme.ts';" "${INDEX}" 2>/dev/null && return 0

    return 1
}

install_theme(){
    require_root
    require_commands
    check_os
    validate_panel

    if is_installed; then
        warn "ZERIX is already installed. Use [3] Theme Update."
        return 0
    fi

    load_resources

    echo
    say "Installing ZERIX Theme v${VERSION}"
    backup_current

    if ! copy_theme_files; then
        die "Could not copy ZERIX theme files."
    fi

    add_imports

    if ! build_panel; then
        warn "Build failed. Restoring the pre-install backup..."
        restore_backup "${BACKUP}" || true
        die "Installation failed and the backup was restored."
    fi

    mark_installed

    echo
    ok "ZERIX Theme installed successfully."
    ok "Backup: ${BACKUP}"
}

update_theme(){
    require_root
    require_commands
    check_os
    validate_panel

    load_resources

    echo
    say "Updating ZERIX Theme to v${VERSION}"
    backup_current

    if ! copy_theme_files; then
        die "Could not copy ZERIX theme files."
    fi

    add_imports

    if ! build_panel; then
        warn "Build failed. Restoring the pre-update backup..."
        restore_backup "${BACKUP}" || true
        die "Update failed and the backup was restored."
    fi

    mark_installed

    echo
    ok "ZERIX Theme updated successfully."
    ok "Backup: ${BACKUP}"
}

uninstall_theme(){
    require_root
    require_commands
    check_os
    validate_panel

    if ! is_installed; then
        warn "ZERIX does not appear to be installed."
        return 0
    fi

    echo
    say "Uninstalling ZERIX Theme..."

    # Always make a backup of the current state before uninstall.
    backup_current

    remove_imports
    rm -rf "${THEME_DIR}"
    rm -f "${PANEL}/public/assets/zerix-icon.svg"
    rm -f "${PANEL}/public/assets/zerix-theme.json"

    if ! build_panel; then
        warn "Uninstall build failed. Restoring the pre-uninstall backup..."
        restore_backup "${BACKUP}" || true
        die "Uninstall failed and the backup was restored."
    fi

    rm -f "${STATE_FILE}"

    echo
    ok "ZERIX Theme uninstalled successfully."
}

main(){
    require_root
    require_commands

    while true; do
        banner

        read -r -p "  Select an option [0-3]: " choice

        case "${choice}" in
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
