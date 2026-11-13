#!/usr/bin/env bash
# Monitoring.

mon_netdata() {
  need_root; hr; echo -e "  ${C_PURPLE}${C_BOLD}Netdata${C_RESET} — real-time monitoring dashboard"; hr
  spin "Installing Netdata (official kickstart)" bash -c "curl -fsSL https://my-netdata.io/kickstart.sh -o /tmp/netdata-kickstart.sh && bash /tmp/netdata-kickstart.sh --non-interactive --stable-channel"
  local IP; IP=$(hostname -I | awk '{print $1}')
  hr; ok "Dashboard: http://${IP}:19999"; press_enter
}

mon_vnstat() {
  need_root; hr; echo -e "  ${C_PURPLE}${C_BOLD}vnstat${C_RESET} — bandwidth usage monitor"; hr
  spin "Installing vnstat" apt-get install -y vnstat
  spin "Enabling vnstat" systemctl enable --now vnstat
  hr; ok "Tracking started — check with: vnstat  (data builds up over the first day)"; press_enter
}

mon_grafana() {
  need_root; detect_os; hr; echo -e "  ${C_PURPLE}${C_BOLD}Grafana${C_RESET}"; hr
  spin "Adding Grafana apt key" bash -c "mkdir -p /etc/apt/keyrings && curl -fsSL https://apt.grafana.com/gpg.key | gpg --dearmor -o /etc/apt/keyrings/grafana.gpg"
  echo "deb [signed-by=/etc/apt/keyrings/grafana.gpg] https://apt.grafana.com stable main" > /etc/apt/sources.list.d/grafana.list
  spin "Refreshing package lists" apt-get update -y
  spin "Installing Grafana" apt-get install -y grafana
  spin "Enabling Grafana" systemctl enable --now grafana-server
  local IP; IP=$(hostname -I | awk '{print $1}')
  hr; ok "Grafana: http://${IP}:3000 — default login admin/admin (change on first login)"; press_enter
}

mon_prometheus() {
  need_root; hr; echo -e "  ${C_PURPLE}${C_BOLD}Prometheus${C_RESET}"; hr
  local VER="2.54.1"
  local ARCH; ARCH=$([ "$(uname -m)" = "aarch64" ] && echo arm64 || echo amd64)
  id prometheus &>/dev/null || useradd --no-create-home --shell /usr/sbin/nologin prometheus
  mkdir -p /etc/prometheus /var/lib/prometheus
  pushd /tmp >/dev/null
  spin "Downloading Prometheus ${VER}" curl -fsSL -o prom.tar.gz \
    "https://github.com/prometheus/prometheus/releases/download/v${VER}/prometheus-${VER}.linux-${ARCH}.tar.gz"
  tar -xzf prom.tar.gz
  cp "prometheus-${VER}.linux-${ARCH}/prometheus" "prometheus-${VER}.linux-${ARCH}/promtool" /usr/local/bin/
  cp -r "prometheus-${VER}.linux-${ARCH}/consoles" "prometheus-${VER}.linux-${ARCH}/console_libraries" /etc/prometheus/
  [ -f /etc/prometheus/prometheus.yml ] || cat > /etc/prometheus/prometheus.yml <<'EOF'
global:
  scrape_interval: 15s
scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']
EOF
  chown -R prometheus:prometheus /etc/prometheus /var/lib/prometheus
  rm -rf prom.tar.gz "prometheus-${VER}.linux-${ARCH}"
  popd >/dev/null
  cat > /etc/systemd/system/prometheus.service <<'EOF'
[Unit]
Description=Prometheus
After=network-online.target

[Service]
User=prometheus
ExecStart=/usr/local/bin/prometheus --config.file=/etc/prometheus/prometheus.yml --storage.tsdb.path=/var/lib/prometheus/
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF
  spin "Enabling Prometheus" bash -c "systemctl daemon-reload && systemctl enable --now prometheus"
  local IP; IP=$(hostname -I | awk '{print $1}')
  hr; ok "Prometheus: http://${IP}:9090"; press_enter
}
