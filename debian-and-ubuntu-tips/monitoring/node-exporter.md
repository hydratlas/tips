# Node Exporter
## node-exporter-textfile-collector-scriptsのインストール
公式サイトは[node-exporter-textfile-collector-scripts/ipmitool at master · prometheus-community/node-exporter-textfile-collector-scripts](https://github.com/prometheus-community/node-exporter-textfile-collector-scripts)。

### 必要なパッケージのインストール
```bash
# Debian系の場合
sudo apt-get install -y moreutils python3-apt python3-prometheus-client ipmitool jq nvme-cli smartmontools rsync

# RHEL系の場合
sudo yum install -y epel-release moreutils
```

### 本体のインストールおよびサービスの設定
```bash
cd "$HOME" &&
mkdir -p prometheus-node-exporter-collectors &&
wget -O - https://github.com/prometheus-community/node-exporter-textfile-collector-scripts/archive/refs/heads/master.tar.gz | tar xvfz - -C prometheus-node-exporter-collectors --strip-components 1 &&
rm -dr prometheus-node-exporter-collectors/mock &&
rm -dr prometheus-node-exporter-collectors/.circleci &&
rm -dr prometheus-node-exporter-collectors/.github &&
rm prometheus-node-exporter-collectors/CODE_OF_CONDUCT.md &&
rm prometheus-node-exporter-collectors/LICENSE &&
rm prometheus-node-exporter-collectors/MAINTAINERS.md &&
rm prometheus-node-exporter-collectors/README.md &&
rm prometheus-node-exporter-collectors/SECURITY.md &&
rm prometheus-node-exporter-collectors/.flake8 &&
mkdir -p prometheus-node-exporter-collectors/tmp &&
mkdir -p prometheus-node-exporter-collectors/prom &&
sudo mkdir -p /opt/prometheus-node-exporter-collectors &&
sudo rsync -rpt prometheus-node-exporter-collectors/ /opt/prometheus-node-exporter-collectors/ &&
rm -dr prometheus-node-exporter-collectors &&
sudo tee /opt/prometheus-node-exporter-collectors/collectors <<'EOF' >/dev/null &&
#!/bin/bash
TMPDIR=/opt/prometheus-node-exporter-collectors/tmp
COLLECTORSDIR=/opt/prometheus-node-exporter-collectors
PROMDIR=/opt/prometheus-node-exporter-collectors/prom
"$COLLECTORSDIR/btrfs_stats.py"                      | sponge "$PROMDIR/btrfs_stats.prom"
/usr/bin/ipmitool sensor | "$COLLECTORSDIR/ipmitool" | sponge "$PROMDIR/ipmitool_sensor.prom"
"$COLLECTORSDIR/mellanox_hca_temp"                   | sponge "$PROMDIR/mellanox_hca_temp.prom"
"$COLLECTORSDIR/node_os_info.sh"                     | sponge "$PROMDIR/node_os_info.prom"
"$COLLECTORSDIR/nvme_metrics.sh"                     | sponge "$PROMDIR/nvme_metrics.prom"
"$COLLECTORSDIR/smartmon.sh"                         | sponge "$PROMDIR/smartmon.prom"
"$COLLECTORSDIR/storcli.py"                          | sponge "$PROMDIR/storcli.prom"
EOF
sudo chmod a+x /opt/prometheus-node-exporter-collectors/collectors &&
sudo tee /etc/systemd/system/prometheus-node-exporter-collectors.service <<'EOF' >/dev/null &&
[Unit]
Description=prometheus-node-exporter-collectors

[Service]
Type=oneshot
ExecStart=/opt/prometheus-node-exporter-collectors/collectors
EOF
sudo systemctl daemon-reload &&
sudo systemctl start prometheus-node-exporter-collectors.service
```

### 確認
```bash
sudo systemctl status prometheus-node-exporter-collectors.service
```

## Node Exporterのインストール
公式サイトは[prometheus/node_exporter: Exporter for machine metrics](https://github.com/prometheus/node_exporter)。

### インストール
`VERSION`変数はそのときの最新バージョンに合わせて適切に書き換える。
```bash
VERSION="1.8.2" &&
ARCH="$(dpkg --print-architecture)" &&
cd "$HOME" &&
mkdir -p node_exporter &&
wget -O - "https://github.com/prometheus/node_exporter/releases/download/v$VERSION/node_exporter-$VERSION.linux-$ARCH.tar.gz" | tar xvfz - -C node_exporter --strip-components 1 &&
sudo install -m 0775 -D -t /usr/local/bin node_exporter/node_exporter &&
rm -dr node_exporter
```
アップデートの際はこれと同様のことを行った上で、`sudo systemctl restart node_exporter.service`を実行する。

### 設定・起動・常時起動化
```bash
getent group node-exporter 2>&1 > /dev/null || sudo groupadd -r node-exporter &&
getent passwd node-exporter 2>&1 > /dev/null || sudo useradd -r -g node-exporter -s /usr/sbin/nologin node-exporter &&
sudo tee "/etc/systemd/system/node_exporter.service" <<'EOF' >/dev/null &&
[Unit]
Description=Node Exporter
After=network.target

[Service]
User=node-exporter
Group=node-exporter
Type=simple
ExecStart=/usr/local/bin/node_exporter --collector.textfile.directory=/opt/prometheus-node-exporter-collectors/prom
Restart=always

[Install]
WantedBy=multi-user.target
EOF
sudo systemctl daemon-reload &&
sudo systemctl enable --now node_exporter.service
```

### 確認
```bash
sudo systemctl status node_exporter.service

node_exporter --version

wget -q -O - http://localhost:9100/metrics
```