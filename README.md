# 💜 Zerix V4 — Pterodactyl Theme

> A premium, modern and responsive Pterodactyl panel theme inspired by the visual language of modern commercial hosting themes.

---

## 🚀 One-Command Installation

Run this command on your Pterodactyl server:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/alokgame2009-bot/zerix-theme/main/zerix.sh)
```

The installer automatically checks your system, detects the Pterodactyl panel, creates a backup and prepares the Zerix theme.

---

## ✨ Features

### 👤 Client Panel

* Modern dashboard
* Server cards
* Compact navigation
* Server overview
* Console styling
* File manager styling
* Database styling
* Schedule styling
* Backup styling
* Network styling
* Startup styling
* Server settings
* Account settings
* Responsive mobile interface

### 🔐 Authentication

* Login page styling
* Register page styling
* Password recovery styling
* Modern form controls
* Premium dark UI

### 🛡️ Admin Panel

* Modern admin dashboard
* Admin cards
* Tables
* Forms
* Buttons
* Alerts
* Dark admin interface
* Responsive admin layout

### 🎨 Theme

* Dark premium interface
* Blue/Purple accent system
* Gradient buttons
* Glass-style cards
* Rounded components
* Soft shadows
* Hover animations
* Responsive layout
* Custom CSS variables

---

## 🔌 Blueprint

Zerix is structured for Blueprint-based Pterodactyl customization.

Included Blueprint files:

```text
conf.yml
components/
resources/
```

The package contains dashboard and admin styling/wrapper definitions.

---

## 📦 Installation

### Automatic Installation

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/alokgame2009-bot/zerix-theme/main/zerix.sh)
```

### Manual

Clone the repository:

```bash
git clone https://github.com/alokgame2009-bot/zerix-theme.git
```

Enter the directory:

```bash
cd zerix-theme
```

Make the installer executable:

```bash
chmod +x zerix.sh
```

Run:

```bash
sudo ./zerix.sh
```

---

## 🔄 After Installation

If the panel was already open in your browser, perform a hard refresh.

You can also clear the Laravel cache:

```bash
cd /var/www/pterodactyl
php artisan optimize:clear
```

For a source frontend build:

```bash
cd /var/www/pterodactyl
yarn
export NODE_OPTIONS=--openssl-legacy-provider
yarn build:production
php artisan optimize:clear
```

---

## 💾 Automatic Backup

Before making changes, the installer creates a timestamped backup under:

```text
/var/backups/zerix/
```

Example:

```text
/var/backups/zerix/20261005-193000/
```

---

## 📁 Repository Structure

```text
zerix-theme/
│
├── zerix.sh
├── install.sh
├── update.sh
├── remove.sh
│
├── conf.yml
├── README.md
├── BUILD.md
├── ZERIX_UI_SPEC.md
│
├── components/
│   ├── Components.yml
│   ├── ZerixBadge.tsx
│   └── ZerixPage.tsx
│
└── resources/
    ├── css/
    │   ├── dashboard.css
    │   └── admin.css
    │
    └── views/
        ├── dashboard-wrapper.blade.php
        ├── admin-wrapper.blade.php
        └── admin.blade.php
```

---

## ⚙️ Requirements

Recommended environment:

```text
Ubuntu 22.04 / 24.04
Pterodactyl Panel
PHP 8.2+
Node.js
Yarn
Blueprint (when using Blueprint installation)
```

Always test the theme on a staging panel before applying it to production.

---

## 🎯 Design

Zerix uses a premium hosting-panel design language with:

```text
Dark Background
       +
Purple / Blue Accent
       +
Rounded Cards
       +
Soft Shadows
       +
Responsive Navigation
       +
Modern Forms
       +
Smooth Hover Effects
```

---

## ⚠️ Important

Zerix is an **original Arix-inspired implementation**.

It does **not** contain or redistribute proprietary Arix source code, private code or original Arix assets.

For the official Arix theme, obtain a valid license from the Arix developer.

---

## 🧑‍💻 Author

**Zerix Theme**

GitHub:

```text
https://github.com/alokgame2009-bot/zerix-theme
```

---

## ⭐ Support

If you like Zerix, give the repository a ⭐ on GitHub.

```text
Zerix V4
Premium Pterodactyl UI
```
