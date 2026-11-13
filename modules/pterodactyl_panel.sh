#!/usr/bin/env bash
# Pterodactyl Panel installer — PHP, MariaDB, nginx/Redis, panel files, DB, first admin.

install_pterodactyl_panel() {
  need_root
  detect_os
  hr
  echo -e "  ${C_PURPLE}${C_BOLD}Pterodactyl Panel${C_RESET} — fresh install"
  hr

  local FQDN DB_NAME DB_USER DB_PASS USE_SSL
  FQDN=$(ask "Panel domain (e.g. panel.example.com)")
  [ -z "$FQDN" ] && die "Domain is required."
  DB_NAME=$(ask "Database name" "panel")
  DB_USER=$(ask "Database user" "pterodactyl")
  DB_PASS=$(ask_secret "Database password for $DB_USER (blank = auto-generate)")
  [ -z "$DB_PASS" ] && DB_PASS=$(tr -dc 'A-Za-z0-9' </dev/urandom | head -c 24)
  if confirm "Issue a free Let's Encrypt SSL cert for $FQDN (needs DNS already pointed here)?"; then
    USE_SSL="yes"
  else
    USE_SSL="no"
  fi

  info "Will install for ${C_BOLD}$FQDN${C_RESET} — DB '$DB_NAME' / user '$DB_USER'. SSL: $USE_SSL"
  confirm "Proceed?" || { warn "Cancelled."; return; }

  export DEBIAN_FRONTEND=noninteractive
  spin "Updating package lists" apt-get update -y
  spin "Installing base packages" apt-get install -y software-properties-common curl apt-transport-https \
    ca-certificates gnupg lsb-release tar unzip git

  if [ "$OS_ID" = "ubuntu" ]; then
    spin "Adding PHP PPA (ondrej/php)" add-apt-repository -y ppa:ondrej/php
  else
    spin "Adding Sury PHP repo" bash -c "curl -fsSL https://packages.sury.org/php/apt.gpg | gpg --dearmor -o /usr/share/keyrings/deb.sury.org-php.gpg && echo 'deb [signed-by=/usr/share/keyrings/deb.sury.org-php.gpg] https://packages.sury.org/php/ $(lsb_release -sc) main' > /etc/apt/sources.list.d/php.list"
  fi
  spin "Refreshing package lists" apt-get update -y

  local PHP_PKGS="php8.3 php8.3-{common,cli,gd,mysql,mbstring,bcmath,xml,fpm,curl,zip,intl,redis}"
  spin "Installing PHP 8.3 + extensions" bash -c "apt-get install -y $PHP_PKGS || apt-get install -y php8.1 php8.1-{common,cli,gd,mysql,mbstring,bcmath,xml,fpm,curl,zip,intl,redis}"
  spin "Installing MariaDB, nginx, redis" apt-get install -y mariadb-server nginx redis-server

  if [ ! -f /usr/local/bin/composer ]; then
    spin "Installing Composer" bash -c "curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer"
  fi

  mkdir -p /var/www/pterodactyl
  pushd /var/www/pterodactyl >/dev/null
  spin "Downloading Pterodactyl Panel (latest release)" bash -c \
    "curl -fsSL -o panel.tar.gz https://github.com/pterodactyl/panel/releases/latest/download/panel.tar.gz && tar -xzf panel.tar.gz && chmod -R 755 storage/* bootstrap/cache/ && rm panel.tar.gz"

  spin "composer install (no-dev, optimized)" bash -c \
    "COMPOSER_ALLOW_SUPERUSER=1 composer install --no-dev --optimize-autoloader --no-interaction"

  [ -f .env ] || cp .env.example .env
  spin "Generating app key" php artisan key:generate --force --no-interaction

  spin "Creating database + user" bash -c "mysql -u root <<SQL
CREATE DATABASE IF NOT EXISTS \`${DB_NAME}\`;
CREATE USER IF NOT EXISTS '${DB_USER}'@'127.0.0.1' IDENTIFIED BY '${DB_PASS}';
GRANT ALL PRIVILEGES ON \`${DB_NAME}\`.* TO '${DB_USER}'@'127.0.0.1' WITH GRANT OPTION;
FLUSH PRIVILEGES;
SQL"

  sed -i \
    -e "s/^DB_HOST=.*/DB_HOST=127.0.0.1/" \
    -e "s/^DB_PORT=.*/DB_PORT=3306/" \
    -e "s/^DB_DATABASE=.*/DB_DATABASE=${DB_NAME}/" \
    -e "s/^DB_USERNAME=.*/DB_USERNAME=${DB_USER}/" \
    -e "s/^DB_PASSWORD=.*/DB_PASSWORD=${DB_PASS}/" \
    -e "s#^APP_URL=.*#APP_URL=http${USE_SSL:+s}://${FQDN}#" \
    .env

  spin "Running database migrations + seeders" php artisan migrate --seed --force --no-interaction

  echo
  info "Create the first admin account:"
  local A_EMAIL A_USER A_FIRST A_LAST A_PASS
  A_EMAIL=$(ask "Admin email")
  A_USER=$(ask "Admin username" "admin")
  A_FIRST=$(ask "Admin first name" "Admin")
  A_LAST=$(ask "Admin last name" "User")
  A_PASS=$(ask_secret "Admin password (blank = auto-generate)")
  [ -z "$A_PASS" ] && A_PASS=$(tr -dc 'A-Za-z0-9!@#%' </dev/urandom | head -c 16)

  spin "Creating admin user" php artisan p:user:make \
    --email="$A_EMAIL" --username="$A_USER" --name-first="$A_FIRST" --name-last="$A_LAST" \
    --password="$A_PASS" --admin=1 --no-interaction

  spin "Setting file ownership" chown -R www-data:www-data /var/www/pterodactyl/*
  popd >/dev/null

  # queue worker service
  cat > /etc/systemd/system/pteroq.service <<'EOF'
[Unit]
Description=Pterodactyl Queue Worker
After=redis-server.service

[Service]
User=www-data
Group=www-data
Restart=always
ExecStart=/usr/bin/php /var/www/pterodactyl/artisan queue:work --queue=high,standard,low --sleep=3 --tries=3
StartLimitInterval=180
StartLimitBurst=30
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
  spin "Enabling queue worker service" bash -c "systemctl daemon-reload && systemctl enable --now pteroq.service"

  # cron for scheduler
  ( crontab -l 2>/dev/null | grep -v 'pterodactyl/artisan schedule:run' ; \
    echo "* * * * * php /var/www/pterodactyl/artisan schedule:run >> /dev/null 2>&1" ) | crontab -

  # nginx vhost
  local PHP_SOCK
  PHP_SOCK=$(ls /run/php/php*-fpm.sock 2>/dev/null | head -n1)
  cat > /etc/nginx/sites-available/pterodactyl.conf <<EOF
server {
    listen 80;
    server_name ${FQDN};
    root /var/www/pterodactyl/public;
    index index.php;

    access_log /var/log/nginx/pterodactyl.access.log;
    error_log  /var/log/nginx/pterodactyl.error.log error;

    client_max_body_size 100m;
    client_body_timeout 120s;

    location / { try_files \$uri \$uri/ /index.php?\$query_string; }
    location ~ \.php\$ {
        fastcgi_split_path_info ^(.+\.php)(/.+)\$;
        fastcgi_pass unix:${PHP_SOCK};
        fastcgi_index index.php;
        include fastcgi_params;
        fastcgi_param PHP_VALUE "upload_max_filesize = 100M \n post_max_size=100M";
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        fastcgi_param HTTP_PROXY "";
        fastcgi_param SERVER_NAME \$host;
        fastcgi_read_timeout 150;
    }
    location ~ /\.ht { deny all; }
}
EOF
  ln -sf /etc/nginx/sites-available/pterodactyl.conf /etc/nginx/sites-enabled/pterodactyl.conf
  rm -f /etc/nginx/sites-enabled/default
  spin "Reloading nginx" bash -c "nginx -t && systemctl reload nginx"

  if [ "$USE_SSL" = "yes" ]; then
    spin "Installing certbot" apt-get install -y certbot python3-certbot-nginx
    if certbot --nginx -d "$FQDN" --non-interactive --agree-tos -m "$A_EMAIL" --redirect; then
      ok "SSL issued for $FQDN"
    else
      warn "Certbot failed (DNS not pointed yet?) — panel is reachable over http:// for now, rerun certbot later."
    fi
  fi

  hr
  ok "Pterodactyl Panel installed."
  echo -e "  URL:      ${C_BOLD}http${USE_SSL:+s}://${FQDN}${C_RESET}"
  echo -e "  Login:    ${C_BOLD}${A_EMAIL}${C_RESET} / ${C_BOLD}${A_PASS}${C_RESET}  ${C_GREY}(save this!)${C_RESET}"
  echo -e "  DB:       ${DB_NAME} / ${DB_USER} / ${DB_PASS}"
  echo -e "  ${C_YELLOW}Next:${C_RESET} log in, create a Location + Node, then run this installer's Wings option on"
  echo -e "        each game-server host, using the 'auto-deploy' command the Node page gives you."
  hr
  press_enter
}
