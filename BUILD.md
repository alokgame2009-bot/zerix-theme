# Build / deployment notes

Blueprint's extension model supports dashboard CSS/wrappers/components and admin view/CSS/wrapper.

For a direct source integration on a staging panel:
1. Back up `/var/www/pterodactyl/resources`.
2. Copy the theme resources.
3. Import `resources/css/dashboard.css` from the panel's frontend CSS entry.
4. Run `yarn`.
5. For Node 17+, set `NODE_OPTIONS=--openssl-legacy-provider`.
6. Run `yarn build:production`.
7. Clear Laravel caches.

Do not test first on a production panel.
