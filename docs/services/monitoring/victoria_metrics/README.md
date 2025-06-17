# VictoriaMetrics

VictoriaMetricsは、高性能で費用対効果の高い時系列データベースです。Prometheusと互換性があり、長期保存に最適化されています。このドキュメントでは、Ansible roleを使用した自動設定と手動での設定手順の両方を説明します。

## Ansible Roleによる設定

このAnsible roleは、VictoriaMetrics（シングルノード版）をrootlessコンテナとしてデプロイします。[podman_rootless_quadlet_base](../../infrastructure/container/podman_rootless_quadlet_base/README.md)ロールを使用して共通のセットアップを行います。

### 要件

- Ansible 2.9以上
- Podmanがインストールされていること
- 対応OS: Ubuntu (focal, jammy), Debian (buster, bullseye), RHEL/CentOS (8, 9)

### ロール変数

| 変数名 | デフォルト値 | 説明 |
|--------|--------------|------|
| `victoria_metrics_user` | `monitoring` | VictoriaMetricsを実行するユーザー名 |
| `victoria_metrics_user_comment` | `VictoriaMetrics rootless user` | ユーザーのコメント |
| `victoria_metrics_app_name` | `victoria-metrics` | アプリケーション名（設定ディレクトリ名に使用） |
| `victoria_metrics_container_image` | `docker.io/victoriametrics/victoria-metrics:latest` | 使用するコンテナイメージ |
| `victoria_metrics_container_port` | `8428` | VictoriaMetricsのリスニングポート |
| `victoria_metrics_network_name` | `monitoring.network` | 使用するコンテナネットワーク |
| `victoria_metrics_service_description` | `VictoriaMetrics Service` | サービスの説明 |
| `victoria_metrics_service_restart` | `always` | コンテナの再起動ポリシー |
| `victoria_metrics_service_restart_sec` | `5` | 再起動間隔（秒） |
| `victoria_metrics_scrape_configs` | デフォルト設定あり | Prometheusスクレイプ設定 |

### 依存関係

なし

### Playbookの例

```yaml
- hosts: monitoring_servers
  roles:
    - role: services.monitoring.victoria_metrics
      vars:
        victoria_metrics_user: "monitoring"
        victoria_metrics_scrape_configs:
          - job_name: node
            static_configs:
              - targets:
                - "192.168.0.10:9100:server1"
                - "192.168.0.11:9100:server2"
            relabel_configs:
              - source_labels: [__address__]
                regex: '([^:]+):(\d+):([^:]+)'
                target_label: instance
                replacement: '${3}:${2}'
              - source_labels: [__address__]
                regex: '([^:]+):(\d+):([^:]+)'
                target_label: __address__
                replacement: '${1}:${2}'
```

### タグ

このroleでは特定のタグは使用していません。

### ハンドラー

- `reload systemd user daemon`: systemdユーザーデーモンをリロード
- `restart victoria_metrics`: VictoriaMetricsサービスを再起動

## トラブルシューティング

```bash
# サービスの状態確認
sudo -u monitoring systemctl --user status victoria-metrics.service

# ログの確認
sudo -u monitoring journalctl --user -u victoria-metrics.service -f

# サービスの再起動
sudo -u monitoring XDG_RUNTIME_DIR=/run/user/$(id -u monitoring) systemctl --user restart victoria-metrics.service

# 設定ファイルの確認
cat /home/monitoring/.config/prometheus/prometheus.yml
```

## 手動での設定手順

### 1. 準備

```bash
# アプリケーション名とユーザー名を設定
APP_NAME="victoria-metrics" &&
QUADLET_USER="monitoring" &&
USER_COMMENT="VictoriaMetrics rootless user"
```

この先は、[podman_rootless_quadlet_base](../../infrastructure/container/podman_rootless_quadlet_base/README.md)を参照。

### 2. Quadletファイルなどの配置

#### ネットワークファイルの作成

```bash
if [ ! -f "/home/monitoring/.config/containers/systemd/monitoring.network" ]; then
sudo -u "monitoring" tee "/home/monitoring/.config/containers/systemd/monitoring.network" << EOF > /dev/null
[Unit]
Description=Monitoring Container Network

[Network]
Label=app=monitoring
EOF
fi
```

#### Prometheus設定ファイルの作成

```bash
# 設定ディレクトリの作成
sudo -u monitoring mkdir -p /home/monitoring/.config/prometheus

# 設定ファイルの作成
sudo -u monitoring tee /home/monitoring/.config/prometheus/prometheus.yml << 'EOF' > /dev/null
scrape_configs:
  - job_name: node
    static_configs:
      - targets:
         - 192.168.0.xxx:9100:label1
         - 192.168.0.xxx:9100:label2
    relabel_configs:
      - source_labels: [__address__]
        regex: '([^:]+):(\d+):([^:]+)'
        target_label: instance
        replacement: '${3}:${2}'
      - source_labels: [__address__]
        regex: '([^:]+):(\d+):([^:]+)'
        target_label: __address__
        replacement: '${1}:${2}'
EOF
```

#### Podman Quadletコンテナファイルの作成

```bash
# データディレクトリの作成
sudo -u monitoring mkdir -p /home/monitoring/.local/share/victoria-metrics-data

# Quadletコンテナ定義ファイルの作成
sudo -u monitoring tee /home/monitoring/.config/containers/systemd/victoria-metrics.container << 'EOF' > /dev/null
[Unit]
Description=VictoriaMetrics Service

[Container]
Image=docker.io/victoriametrics/victoria-metrics:latest
ContainerName=victoria-metrics
Network=monitoring.network
AutoUpdate=registry
LogDriver=journald
UserNS=keep-id
NoNewPrivileges=true
PublishPort=8428:8428
Volume=/home/monitoring/.config/prometheus/prometheus.yml:/etc/prometheus.yml:z
Volume=/home/monitoring/.local/share/victoria-metrics-data:/victoria-metrics-data:Z
Volume=/etc/localtime:/etc/localtime:ro,z
Exec='-promscrape.config=/etc/prometheus.yml'

[Service]
Restart=always
RestartSec=5

[Install]
WantedBy=default.target
EOF

# パーミッションの設定
sudo chmod 644 /home/monitoring/.config/containers/systemd/victoria-metrics.container
```

### 3. サービスおよびタイマーの起動と有効化

[podman_rootless_quadlet_base](../../infrastructure/container/podman_rootless_quadlet_base/README.md)を参照。

## 参考

- [VictoriaMetrics](https://docs.victoriametrics.com/)
- [VictoriaMetrics/package/victoria-metrics.service at master · VictoriaMetrics/VictoriaMetrics](https://github.com/VictoriaMetrics/VictoriaMetrics/blob/master/package/victoria-metrics.service)
- [Prometheusでinstance名をホスト名にしたい #prometheus - Qiita](https://qiita.com/fkshom/items/bafb2160e2c9ca8ded38)