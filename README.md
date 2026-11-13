# The Axion Installer

One menu-driven installer for everything you host: game panels, Discord bots, tools,
and themes — animated terminal UI, built to grow as more modules get added.

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

**Tools**
- ✅ Add swap (size + swappiness, persists via fstab)
- ✅ Basic firewall (ufw — SSH/HTTP/HTTPS + any extra ports you name)
- ✅ Fail2ban (SSH brute-force protection, configurable ban time/attempts)
- ✅ Docker standalone install (+ optional compose plugin)
- ✅ Quick server benchmark (CPU/RAM/disk, optional network speedtest)

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
