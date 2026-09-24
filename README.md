# ZERIX Theme for Pterodactyl

**Power by SkylerNodes • Made by Zyren**

ZERIX is a frontend theme package for Pterodactyl with a simple terminal installer.

## Repository structure

```text
zerix-theme/
├── zerix.sh
├── README.md
├── preview/
│   └── README.txt
└── resources/
    └── scripts/
        └── Zerix/
            ├── main.css
            ├── theme.ts
            └── assets/
                ├── zerix-icon.svg
                └── theme.json
```

## GitHub setup

Upload **all files and folders** above to the root of your GitHub repository. Do not put the repository inside another ZIP when you want the one-command installer to work.

Before using the one-command method, open `zerix.sh` and change:

```bash
REPO_RAW_BASE="https://raw.githubusercontent.com/YOUR_USERNAME/YOUR_REPOSITORY/main"
```

to your real GitHub Raw URL, for example:

```bash
REPO_RAW_BASE="https://raw.githubusercontent.com/zyren/zerix-theme/main"
```

## One-command installer

After the repository is public:

```bash
curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/YOUR_REPOSITORY/main/zerix.sh | sudo bash
```

The script opens the ZERIX menu:

```text
                 ZERIX
                  THEME
        Zerix Theme Installer
        Power by SkylerNodes
        Made by Zyren

  ────────────────────────────────────────────────
    [1]  Zerix Theme Install
    [2]  Theme Uninstall
    [3]  Theme Update
    [0]  Exit
  ────────────────────────────────────────────────
```

## Menu options

### 1 — Zerix Theme Install
- Checks the Pterodactyl frontend path.
- Creates a timestamped backup.
- Installs `resources/scripts/Zerix`.
- Installs the ZERIX icon and metadata.
- Adds the ZERIX CSS/TypeScript imports only once.
- Builds the Pterodactyl production frontend.
- Clears Laravel view/config caches.

### 2 — Theme Uninstall
- Restores the latest ZERIX backup when available.
- Removes ZERIX theme files and imports.
- Rebuilds the frontend.

### 3 — Theme Update
- Creates a fresh backup.
- Downloads/uses the current repository theme files.
- Rebuilds the frontend.

## Custom panel path

For a panel installed somewhere other than `/var/www/pterodactyl`:

```bash
ZERIX_PANEL_PATH=/path/to/pterodactyl curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/YOUR_REPOSITORY/main/zerix.sh | sudo -E bash
```

Or edit the default path in `zerix.sh`.

## Preview

Put screenshots in `preview/`, for example:

```text
preview/
├── dashboard.png
├── login.png
├── server.png
└── settings.png
```

Then reference them in this README with normal GitHub Markdown.

## Compatibility

Designed for Pterodactyl installations that use `resources/scripts` and the normal React production build workflow. Pterodactyl frontend internals can change between releases, so test on a backup/staging panel first.

## Important

ZERIX is a frontend theme package. Pterodactyl continues to provide server management, console/WebSocket handling, SFTP, allocations, databases, backups, schedules and permissions.
