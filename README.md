## ZERIX Theme V4
Modern dark/glass visual layer for Pterodactyl.

One command

```bash <(curl -fsSL https://raw.githubusercontent.com/alokgame2009-bot/zerix-theme/main/zerix.sh)```

Menu: Install, Uninstall, Update, Exit.

## Compatibility
This package targets Pterodactyl 1.12 and Blueprint's extension model. Test on a staging panel before production. Blueprint's current docs support `dashboard.css`, `dashboard.wrapper`, `dashboard.components`, `admin.css`, `admin.view`, and `admin.wrapper`.

## Install
Copy the ZIP to your panel and install it through Blueprint, or place the extension directory in the Blueprint extensions/development workflow.

For a source-based Pterodactyl build, the CSS can also be imported into the panel's frontend entry and rebuilt.

Production frontend build:
```bash
cd /var/www/pterodactyl
yarn
export NODE_OPTIONS=--openssl-legacy-provider
yarn build:production
php artisan view:clear
php artisan config:clear
php artisan cache:clear
```

## GitHub
```bash
git init
git add .
git commit -m "Zerix V3 Pterodactyl theme"
git branch -M main
git remote add origin https://github.com/YOUR-USERNAME/zerix-pterodactyl-theme.git
git push -u origin main
```

## Important
The theme is intentionally original. It recreates a similar premium hosting-panel visual language rather than copying Arix proprietary code/assets.


## Zerix V4 update

V4 adds a polished terminal installer with:
- Large Zerix ASCII branding
- Root and panel-path validation
- Backup before changes
- Blueprint detection
- Laravel cache clearing
- Optional Yarn production build
- Safe failure handling and status messages

### UI direction

The theme is an original premium Pterodactyl UI inspired by the visual language of modern commercial hosting themes: compact navigation, elevated cards, dark surfaces, accent gradients, responsive spacing, forms, tables, server/console surfaces and admin styling.

It is **not** a copy of Arix proprietary source code or assets.
