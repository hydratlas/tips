# Grafana Loki

Grafana Lokiは、ログデータの集約と保存を行うための水平スケーラブルで高可用性のマルチテナントログ集約システムです。このドキュメントでは、Ansible roleを使用した自動設定と手動での設定手順の両方を説明します。

## Ansible Roleによる設定

このAnsible roleは、Grafana Lokiをrootlessコンテナとしてデプロイし、ログ集約サービスを提供します。[podman_rootless_quadlet_base](../../infrastructure/container/podman_rootless_quadlet_base/README.md)ロールを使用して共通のセットアップを行います。

### 要件

- Ansible 2.9以上
- Podmanがインストールされていること
- 対応OS: Ubuntu (focal, jammy), Debian (buster, bullseye), RHEL/CentOS (8, 9)

### ロール変数

| 変数名 | デフォルト値 | 説明 |
|--------|--------------|------|
| `loki_user` | `monitoring` | Lokiを実行するユーザー名 |
| `loki_user_comment` | `Grafana Loki rootless user` | ユーザーのコメント |
| `loki_app_name` | `loki` | アプリケーション名（設定ディレクトリ名に使用） |
| `loki_container_image` | `docker.io/grafana/loki:latest` | 使用するコンテナイメージ |
| `loki_container_port` | `3100` | Lokiのリスニングポート |
| `loki_network_name` | `monitoring.network` | 使用するコンテナネットワーク |
| `loki_service_description` | `Grafana Loki Service` | サービスの説明 |
| `loki_service_restart` | `always` | コンテナの再起動ポリシー |
| `loki_service_restart_sec` | `5` | 再起動間隔（秒） |
| `loki_auth_enabled` | `false` | 認証の有効/無効 |
| `loki_compactor_retention_enabled` | `true` | データ保持ポリシーの有効/無効 |

### 依存関係

なし

### Playbookの例

```yaml
- hosts: monitoring_servers
  roles:
    - role: services.monitoring.loki
      vars:
        loki_user: "monitoring"
        loki_container_port: 3100
```

### タグ

このroleでは特定のタグは使用していません。

### ハンドラー

- `reload systemd user daemon`: systemdユーザーデーモンをリロード
- `restart loki`: Lokiサービスを再起動

## トラブルシューティング
以下のGrafana Loki固有のコマンド以外は、[podman_rootless_quadlet_base](../../infrastructure/container/podman_rootless_quadlet_base/README.md)を参照。

```bash
# リクエスト確認
wget -O - http://localhost:3100/ready # If “ready” is returned, it is OK.

# リクエスト確認（JSON）
wget --method=POST --header="Content-Type: application/json" --body-data='{}' http://localhost:3100/loki/api/v1/push # If “204 No Content” is returned, it is OK.

# コンテナイメージの手動更新
sudo -u monitoring podman pull docker.io/grafana/loki:latest &&
sudo -u monitoring XDG_RUNTIME_DIR=/run/user/$(id -u monitoring) systemctl --user restart loki.service

# 設定ファイルの削除
sudo rm "/home/monitoring/.config/loki/loki.yaml"
```

## 手動での設定手順
### 1. 準備
```bash
# アプリケーション名とユーザー名を設定
APP_NAME="loki" &&
QUADLET_USER="monitoring" &&
USER_COMMENT="Grafana Loki rootless user"
```
この先は、[podman_rootless_quadlet_base](../../../infrastructure/container/podman_rootless_quadlet_base/README.md)を参照。

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

#### 設定ファイルの作成
```bash
sudo -u "monitoring" tee "/home/monitoring/.config/loki/loki.yaml" << EOF > /dev/null
auth_enabled: false

server:
  http_listen_port: 3100
  http_listen_address: 0.0.0.0

common:
  instance_addr: 127.0.0.1
  path_prefix: /loki
  storage:
    filesystem:
      chunks_directory: /loki/chunks
      rules_directory: /loki/rules
  replication_factor: 1
  ring:
    kvstore:
      store: inmemory

schema_config:
  configs:
    - from: 2020-10-24
      store: tsdb
      object_store: filesystem
      schema: v13
      index:
        prefix: index_
        period: 24h

limits_config:
  retention_period: 336h # 14 days
  retention_stream:
    - selector: '{appname="kernel"}'
      period: 13140h # 1.5 year
      priority: 1
    - selector: '{level="error"}'
      period: 1440h # 60 days
      priority: 0

analytics:
  reporting_enabled: false
EOF
```

#### Podman Quadletコンテナファイルの作成
```bash
# Quadletコンテナ定義ファイルの作成
sudo -u "monitoring" mkdir -p "/home/monitoring/.local/share/loki" &&
sudo -u "monitoring" tee "/home/monitoring/.config/containers/systemd/loki.container" << EOF > /dev/null
[Unit]
Description=Grafana Loki Service
After=network-online.target
Wants=network-online.target

[Container]
Image=docker.io/grafana/loki:latest
ContainerName=monitoring
AutoUpdate=registry
LogDriver=journald
Network=monitoring.network
UserNS=keep-id
Exec='-config.file=/loki.yaml'
NoNewPrivileges=true
ReadOnly=true
PublishPort=3100:3100
Volume=/home/monitoring/.config/loki/loki.yaml:/loki.yaml:z
Volume=/home/monitoring/.local/share/loki:/loki:Z
Volume=/etc/localtime:/etc/localtime:ro,z

[Service]
Restart=always
RestartSec=5

[Install]
WantedBy=default.target
EOF

# パーミッションの設定
sudo chmod 644 /home/monitoring/.config/containers/systemd/loki.container
```

### 3. サービスおよびタイマーの起動と有効化
[podman_rootless_quadlet_base](../../../infrastructure/container/podman_rootless_quadlet_base/README.md)を参照。
