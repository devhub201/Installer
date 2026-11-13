#!/usr/bin/env bash
# Docker-based apps — each a known official one-command deploy.

_ensure_docker() {
  if ! command -v docker >/dev/null 2>&1; then
    spin "Installing Docker" bash -c "curl -fsSL https://get.docker.com | sh"
    spin "Enabling Docker" systemctl enable --now docker
  fi
}

docker_portainer() {
  need_root; hr; echo -e "  ${C_PURPLE}${C_BOLD}Portainer${C_RESET} — Docker web UI"; hr
  _ensure_docker
  docker volume create portainer_data >/dev/null
  spin "Running Portainer" docker run -d -p 8000:8000 -p 9443:9443 --name portainer --restart=always \
    -v /var/run/docker.sock:/var/run/docker.sock -v portainer_data:/data portainer/portainer-ce:latest
  local IP; IP=$(hostname -I | awk '{print $1}')
  hr; ok "Portainer: https://${IP}:9443"; press_enter
}

docker_nginx_proxy_manager() {
  need_root; hr; echo -e "  ${C_PURPLE}${C_BOLD}Nginx Proxy Manager${C_RESET}"; hr
  _ensure_docker
  command -v docker-compose >/dev/null 2>&1 || apt-get install -y docker-compose-plugin
  local DIR="/opt/npm"; mkdir -p "$DIR/data" "$DIR/letsencrypt"
  cat > "$DIR/docker-compose.yml" <<'EOF'
services:
  app:
    image: 'jc21/nginx-proxy-manager:latest'
    restart: unless-stopped
    ports:
      - '80:80'
      - '81:81'
      - '443:443'
    volumes:
      - ./data:/data
      - ./letsencrypt:/etc/letsencrypt
EOF
  spin "Starting Nginx Proxy Manager" bash -c "cd $DIR && docker compose up -d"
  local IP; IP=$(hostname -I | awk '{print $1}')
  hr; ok "Admin UI: http://${IP}:81  (default login: admin@example.com / changeme — change it immediately)"; press_enter
}

docker_uptime_kuma() {
  need_root; hr; echo -e "  ${C_PURPLE}${C_BOLD}Uptime Kuma${C_RESET} — status page / uptime monitor"; hr
  _ensure_docker
  docker volume create uptime-kuma-data >/dev/null
  spin "Running Uptime Kuma" docker run -d --restart=always -p 3001:3001 -v uptime-kuma-data:/app/data --name uptime-kuma louislam/uptime-kuma:1
  local IP; IP=$(hostname -I | awk '{print $1}')
  hr; ok "Uptime Kuma: http://${IP}:3001"; press_enter
}

docker_n8n() {
  need_root; hr; echo -e "  ${C_PURPLE}${C_BOLD}n8n${C_RESET} — workflow automation"; hr
  _ensure_docker
  docker volume create n8n_data >/dev/null
  spin "Running n8n" docker run -d --restart=always --name n8n -p 5678:5678 -v n8n_data:/home/node/.n8n docker.n8n.io/n8nio/n8n
  local IP; IP=$(hostname -I | awk '{print $1}')
  hr; ok "n8n: http://${IP}:5678"; press_enter
}

docker_minio() {
  need_root; hr; echo -e "  ${C_PURPLE}${C_BOLD}MinIO${C_RESET} — S3-compatible object storage"; hr
  _ensure_docker
  local USER PASS; USER=$(ask "Root user" "admin"); PASS=$(ask_secret "Root password (blank = auto-generate)")
  [ -z "$PASS" ] && PASS=$(tr -dc 'A-Za-z0-9' </dev/urandom | head -c 20)
  docker volume create minio_data >/dev/null
  spin "Running MinIO" docker run -d --restart=always --name minio -p 9000:9000 -p 9001:9001 \
    -e "MINIO_ROOT_USER=${USER}" -e "MINIO_ROOT_PASSWORD=${PASS}" -v minio_data:/data \
    quay.io/minio/minio server /data --console-address ":9001"
  local IP; IP=$(hostname -I | awk '{print $1}')
  hr; ok "Console: http://${IP}:9001 — login ${USER} / ${PASS} (save this!)"; press_enter
}

docker_watchtower() {
  need_root; hr; echo -e "  ${C_PURPLE}${C_BOLD}Watchtower${C_RESET} — auto-updates your other Docker containers"; hr
  _ensure_docker
  spin "Running Watchtower" docker run -d --restart=always --name watchtower \
    -v /var/run/docker.sock:/var/run/docker.sock containrrr/watchtower --cleanup
  hr; ok "Watchtower is watching all containers on this host and will keep them updated."; press_enter
}

docker_wireguard_easy() {
  need_root; hr; echo -e "  ${C_PURPLE}${C_BOLD}WireGuard (wg-easy)${C_RESET} — VPN server with a web UI"; hr
  _ensure_docker
  local IP; IP=$(curl -fsSL -4 ifconfig.me 2>/dev/null || hostname -I | awk '{print $1}')
  local PASS; PASS=$(ask_secret "Web UI password (blank = auto-generate)")
  [ -z "$PASS" ] && PASS=$(tr -dc 'A-Za-z0-9' </dev/urandom | head -c 16)
  docker volume create wg-easy >/dev/null
  spin "Running wg-easy" docker run -d --name wg-easy --restart=always \
    -e "WG_HOST=${IP}" -e "PASSWORD=${PASS}" \
    -v wg-easy:/etc/wireguard -p 51820:51820/udp -p 51821:51821/tcp \
    --cap-add=NET_ADMIN --cap-add=SYS_MODULE --sysctl "net.ipv4.conf.all.src_valid_mark=1" \
    --sysctl "net.ipv4.ip_forward=1" weejewel/wg-easy
  hr; ok "Web UI: http://${IP}:51821 — password: ${PASS}"; press_enter
}
