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
- ⏳ PufferPanel, CloudPanel — menu entries exist, not built yet.

**Bots**
- ✅ **AVM-Pro** — clones/updates `devhub201/AVM-Pro` and hands off to its own installer
  (so there's one source of truth for that bot's install logic, not two).
- ⏳ AxionHost Tickets — menu entry exists, not wired up yet.

**Tools / Themes** — placeholder sections for now, ready to fill in.

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
