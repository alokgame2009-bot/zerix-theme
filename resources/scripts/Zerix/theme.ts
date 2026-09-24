/*
 * ZERIX Theme v1.0 browser customizer.
 * Root-admin only. Settings are local to the current browser in v1.0.
 */
import './main.css';

type Settings = {
  panelName: string;
  logoUrl: string;
  primary: string;
  secondary: string;
  accent: string;
  radius: string;
  glow: number;
  bgIntensity: number;
  compact: boolean;
  customCss: string;
};

const KEY = 'zerix-theme-settings-v1';

const defaults: Settings = {
  panelName: 'ZERIX',
  logoUrl: '',
  primary: '#8b5cf6',
  secondary: '#22d3ee',
  accent: '#3b82f6',
  radius: '14px',
  glow: 0.18,
  bgIntensity: 0.14,
  compact: false,
  customCss: '',
};

const get = (): Settings => {
  try { return { ...defaults, ...(JSON.parse(localStorage.getItem(KEY) || '{}')) }; }
  catch { return { ...defaults }; }
};

function installZerixIcon() {
  const href = '/assets/zerix-icon.svg';
  let link = document.querySelector<HTMLLinkElement>('link[data-zerix-icon]');
  if (!link) {
    link = document.createElement('link');
    link.rel = 'icon';
    link.type = 'image/svg+xml';
    link.setAttribute('data-zerix-icon', 'true');
    document.head.appendChild(link);
  }
  link.href = href;
}

function rootStyle(s: Settings) {
  const r = document.documentElement;
  r.style.setProperty('--zerix-primary', s.primary);
  r.style.setProperty('--zerix-secondary', s.secondary);
  r.style.setProperty('--zerix-accent', s.accent);
  r.style.setProperty('--zerix-radius', s.radius);
  r.style.setProperty('--zerix-glow', String(s.glow));
  r.style.setProperty('--zerix-bg-intensity', String(s.bgIntensity));
  document.body?.classList.toggle('zerix-compact', s.compact);
  document.title = `${s.panelName} • Pterodactyl`;

  let style = document.getElementById('zerix-custom-css') as HTMLStyleElement | null;
  if (!style) {
    style = document.createElement('style');
    style.id = 'zerix-custom-css';
    document.head.appendChild(style);
  }
  style.textContent = s.customCss || '';
}

function isRootAdmin() {
  const u = (window as any).PterodactylUser;
  return Boolean(u?.rootAdmin || u?.root_admin);
}

function applyLogo(url: string) {
  if (!url) return;
  document.querySelectorAll<HTMLImageElement>('img').forEach(img => {
    const alt = (img.alt || '').toLowerCase();
    if (alt.includes('logo') || img.hasAttribute('data-zerix-logo')) img.src = url;
  });
}

function editor() {
  if (!isRootAdmin() || document.getElementById('zerix-theme-panel')) return;

  const open = document.createElement('button');
  open.id = 'zerix-theme-open';
  open.type = 'button';
  open.textContent = '✦ ZERIX Settings';

  const panel = document.createElement('section');
  panel.id = 'zerix-theme-panel';
  panel.hidden = true;
  panel.innerHTML = `
    <h3>ZERIX Theme v1.0</h3>
    <p>Customize the visual layer in this browser.</p>
    <label>Panel Name</label>
    <input id="zx-name" maxlength="40" type="text">
    <label>Logo URL</label>
    <input id="zx-logo" type="url" placeholder="https://...">
    <div class="zerix-row">
      <div><label>Primary</label><input id="zx-primary" type="color"></div>
      <div><label>Secondary</label><input id="zx-secondary" type="color"></div>
    </div>
    <label>Accent</label>
    <input id="zx-accent" type="color">
    <div class="zerix-row">
      <div><label>Radius</label><input id="zx-radius" type="text" placeholder="14px"></div>
      <div><label>Glow (0–1)</label><input id="zx-glow" type="number" min="0" max="1" step="0.01"></div>
    </div>
    <label>Background intensity (0–1)</label>
    <input id="zx-bg" type="number" min="0" max="1" step="0.01">
    <label class="zerix-check"><input id="zx-compact" type="checkbox"> Compact mode</label>
    <label>Custom CSS</label>
    <textarea id="zx-css" placeholder=".my-class { ... }"></textarea>
    <div class="zerix-actions">
      <button id="zerix-save" type="button">Save</button>
      <button id="zerix-reset" type="button">Reset</button>
    </div>
  `;

  document.body.append(open, panel);

  const fill = () => {
    const s = get();
    (panel.querySelector('#zx-name') as HTMLInputElement).value = s.panelName;
    (panel.querySelector('#zx-logo') as HTMLInputElement).value = s.logoUrl;
    (panel.querySelector('#zx-primary') as HTMLInputElement).value = s.primary;
    (panel.querySelector('#zx-secondary') as HTMLInputElement).value = s.secondary;
    (panel.querySelector('#zx-accent') as HTMLInputElement).value = s.accent;
    (panel.querySelector('#zx-radius') as HTMLInputElement).value = s.radius;
    (panel.querySelector('#zx-glow') as HTMLInputElement).value = String(s.glow);
    (panel.querySelector('#zx-bg') as HTMLInputElement).value = String(s.bgIntensity);
    (panel.querySelector('#zx-compact') as HTMLInputElement).checked = s.compact;
    (panel.querySelector('#zx-css') as HTMLTextAreaElement).value = s.customCss;
  };

  open.onclick = () => { panel.hidden = !panel.hidden; fill(); };

  panel.querySelector('#zerix-save')?.addEventListener('click', () => {
    const s: Settings = {
      panelName: (panel.querySelector('#zx-name') as HTMLInputElement).value.trim() || defaults.panelName,
      logoUrl: (panel.querySelector('#zx-logo') as HTMLInputElement).value.trim(),
      primary: (panel.querySelector('#zx-primary') as HTMLInputElement).value,
      secondary: (panel.querySelector('#zx-secondary') as HTMLInputElement).value,
      accent: (panel.querySelector('#zx-accent') as HTMLInputElement).value,
      radius: (panel.querySelector('#zx-radius') as HTMLInputElement).value.trim() || defaults.radius,
      glow: Math.max(0, Math.min(1, Number((panel.querySelector('#zx-glow') as HTMLInputElement).value) || defaults.glow)),
      bgIntensity: Math.max(0, Math.min(1, Number((panel.querySelector('#zx-bg') as HTMLInputElement).value) || defaults.bgIntensity)),
      compact: (panel.querySelector('#zx-compact') as HTMLInputElement).checked,
      customCss: (panel.querySelector('#zx-css') as HTMLTextAreaElement).value,
    };
    localStorage.setItem(KEY, JSON.stringify(s));
    rootStyle(s);
    applyLogo(s.logoUrl);
  });

  panel.querySelector('#zerix-reset')?.addEventListener('click', () => {
    localStorage.removeItem(KEY);
    rootStyle(defaults);
    fill();
  });
}

installZerixIcon();
rootStyle(get());

const start = () => {
  editor();
  applyLogo(get().logoUrl);
};

if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', start, { once: true });
else start();

new MutationObserver(() => editor()).observe(document.documentElement, { childList: true, subtree: true });
