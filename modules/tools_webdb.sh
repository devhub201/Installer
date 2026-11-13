#!/usr/bin/env bash
# Standalone web/db services + language runtimes.

web_nginx()    { need_root; hr; spin "Installing nginx" apt-get install -y nginx; spin "Enabling nginx" systemctl enable --now nginx; hr; ok "nginx running on port 80."; press_enter; }
web_apache()   { need_root; hr; spin "Installing apache2" apt-get install -y apache2; spin "Enabling apache2" systemctl enable --now apache2; hr; ok "Apache running on port 80."; press_enter; }
web_mariadb()  { need_root; hr; spin "Installing MariaDB" apt-get install -y mariadb-server; spin "Enabling MariaDB" systemctl enable --now mariadb; confirm "Run mysql_secure_installation now?" && mysql_secure_installation; hr; press_enter; }
web_postgres() { need_root; hr; spin "Installing PostgreSQL" apt-get install -y postgresql postgresql-contrib; spin "Enabling PostgreSQL" systemctl enable --now postgresql; hr; ok "PostgreSQL running."; press_enter; }
web_redis()    { need_root; hr; spin "Installing Redis" apt-get install -y redis-server; spin "Enabling Redis" systemctl enable --now redis-server; hr; ok "Redis running on port 6379."; press_enter; }
web_composer() { need_root; hr; spin "Installing Composer" bash -c "curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer"; hr; ok "Composer: $(composer --version 2>/dev/null)"; press_enter; }

web_nodejs() {
  need_root; hr; echo -e "  ${C_PURPLE}${C_BOLD}Node.js${C_RESET}"; hr
  local V; V=$(ask "Node.js major version" "20")
  spin "Adding NodeSource repo" bash -c "curl -fsSL https://deb.nodesource.com/setup_${V}.x | bash -"
  spin "Installing Node.js" apt-get install -y nodejs
  hr; ok "Node $(node -v 2>/dev/null) / npm $(npm -v 2>/dev/null) installed."; press_enter
}

web_python() {
  need_root; hr
  spin "Installing Python3, pip, venv" apt-get install -y python3 python3-pip python3-venv
  hr; ok "Python $(python3 --version)"; press_enter
}

web_phpmyadmin() {
  need_root; hr; echo -e "  ${C_PURPLE}${C_BOLD}phpMyAdmin${C_RESET}"; hr
  [ -f /var/www/pterodactyl/.env ] || warn "No panel detected — make sure PHP + a webserver are already installed."
  echo "phpmyadmin phpmyadmin/dbconfig-install boolean true" | debconf-set-selections
  echo "phpmyadmin phpmyadmin/app-password-confirm password" | debconf-set-selections
  echo "phpmyadmin phpmyadmin/mysql/admin-pass password" | debconf-set-selections
  echo "phpmyadmin phpmyadmin/mysql/app-pass password" | debconf-set-selections
  echo "phpmyadmin phpmyadmin/reconfigure-webserver multiselect nginx" | debconf-set-selections
  DEBIAN_FRONTEND=noninteractive spin "Installing phpMyAdmin" apt-get install -y phpmyadmin
  hr; ok "phpMyAdmin installed — usually at /phpmyadmin on your webserver."; press_enter
}

web_certbot_standalone() {
  need_root; hr; echo -e "  ${C_PURPLE}${C_BOLD}Certbot${C_RESET} — SSL for an existing site"; hr
  spin "Installing certbot" apt-get install -y certbot python3-certbot-nginx
  local D; D=$(ask "Domain to secure"); [ -z "$D" ] && { warn "Cancelled."; press_enter; return; }
  local E; E=$(ask "Email for renewal notices")
  certbot --nginx -d "$D" --non-interactive --agree-tos -m "$E" --redirect && ok "SSL issued for $D" || warn "Certbot failed — check DNS/nginx config."
  hr; press_enter
}

web_static_site() {
  need_root; hr; echo -e "  ${C_PURPLE}${C_BOLD}Quick static site${C_RESET} — folder + nginx + optional SSL"; hr
  command -v nginx >/dev/null 2>&1 || spin "Installing nginx" apt-get install -y nginx
  local D; D=$(ask "Domain (or server IP if no domain yet)")
  local ROOT; ROOT=$(ask "Site root folder" "/var/www/${D}")
  mkdir -p "$ROOT"
  [ -f "$ROOT/index.html" ] || echo "<h1>${D} is live 🚀 — served by The Axion Installer</h1>" > "$ROOT/index.html"
  cat > "/etc/nginx/sites-available/${D}.conf" <<EOF
server {
    listen 80;
    server_name ${D};
    root ${ROOT};
    index index.html;
}
EOF
  ln -sf "/etc/nginx/sites-available/${D}.conf" "/etc/nginx/sites-enabled/${D}.conf"
  spin "Reloading nginx" bash -c "nginx -t && systemctl reload nginx"
  if confirm "Issue free SSL for ${D} now (DNS must already point here)?"; then
    command -v certbot >/dev/null 2>&1 || spin "Installing certbot" apt-get install -y certbot python3-certbot-nginx
    certbot --nginx -d "$D" --non-interactive --agree-tos -m "$(ask "Email" "")" --redirect || warn "Certbot failed."
  fi
  hr; ok "Site root: $ROOT — http://${D}"; press_enter
}
