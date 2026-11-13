# The Axion Installer

One menu-driven installer for everything you host: game panels, Discord bots, tools,
and themes — 50+ real installable items behind an animated terminal UI, built to grow
as more modules get added.

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/devhub201/installer/main/bootstrap.sh)
```

or clone it yourself:

```bash
git clone https://github.com/devhub201/installer
cd installer
sudo bash installer.sh
```

## What's in it right now

**Panels**
- ✅ **Pterodactyl Panel** — full fresh install: PHP 8.3, MariaDB, nginx, Redis, Composer,
  DB + first admin account creation, queue worker + cron, optional free SSL via certbot.
- ✅ **Pterodactyl Wings** — Docker + the Wings daemon as a systemd service; paste the
  panel's own "auto-deploy" command (from Admin → Nodes → your node) and it configures
  and starts itself.
- ✅ **PufferPanel** — installed via its official apt repo.
- ✅ **CloudPanel** — installed via its official installer script (pick your DB engine).

**Bots**
- ✅ **AVM-Pro** — clones/updates `devhub201/AVM-Pro` and hands off to its own installer
  (so there's one source of truth for that bot's install logic, not two).
- ✅ **AxionHost Tickets** — same pattern, clones `devhub201/axionhost-tickets` and runs
  its own `install.sh`.
- ✅ **Deploy any bot from git** — generic: clone, venv, requirements.txt, systemd
  service, for any bot that doesn't ship its own installer.

**Tools** — grouped into 6 sub-menus, 35+ items total:
- **System**: update & upgrade, add swap, create sudo user, set hostname/timezone, dev
  basics (build-essential/git/curl/wget/unzip), CLI tools (htop/btop/tmux/screen/neofetch),
  disk cleanup, custom login banner (MOTD).
- **Security**: ufw firewall, fail2ban, SSH hardening (disable root/password login, change
  port), automatic security updates, ClamAV scan, rkhunter.
- **Web & Database**: nginx, Apache, MariaDB, PostgreSQL, Redis, phpMyAdmin, standalone
  Certbot SSL, Node.js, Python3, Composer, quick static-site deploy.
- **Docker & Apps**: Docker Engine, Portainer, Nginx Proxy Manager, Uptime Kuma, n8n,
  MinIO, Watchtower, WireGuard VPN (wg-easy with a web UI).
- **Monitoring**: Netdata, vnstat, Grafana, Prometheus, quick server benchmark.
- **Network & Backup**: Tailscale, vsftpd FTP, rclone, scheduled tar+cron backups with
  auto-rotation.

**Themes**
- ✅ Apply a Pterodactyl theme from any git repo — runs the theme's own `install.sh` if
  it ships one, otherwise does a generic resources/public copy + asset rebuild. (No
  specific theme is bundled — theme repos come and go, so point it at whichever one
  you trust.)

## Adding a new module

1. Drop a `modules/your_thing.sh` with one function, e.g. `install_your_thing()`, using
   the helpers in `lib/common.sh` (`spin`, `confirm`, `ask`, `info`/`ok`/`warn`/`err`/`die`).
2. `source` it near the top of `installer.sh`.
3. Add a line + case branch in the relevant `*_menu()` function.

## Notes

- Supports Ubuntu and Debian (20.04+/11+). Must be run as root.
- Every run logs to `/var/log/axion-installer.log` (falls back to `/tmp` if that's not
  writable) — check it first if a step fails; the installer also prints the last lines
  of a failing command's own output.
- Nothing here phones home or touches anything outside the host you run it on.
