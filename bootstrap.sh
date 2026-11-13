#!/usr/bin/env bash
# One-liner entry point:
#   bash <(curl -fsSL https://raw.githubusercontent.com/devhub201/installer/main/bootstrap.sh)
set -euo pipefail
DEST="/opt/axion-installer"
if [ -d "$DEST/.git" ]; then
  git -C "$DEST" pull --ff-only
else
  rm -rf "$DEST"
  git clone --depth 1 https://github.com/devhub201/installer "$DEST"
fi
exec bash "$DEST/installer.sh"
