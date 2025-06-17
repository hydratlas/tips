# Grafana Loki

水平スケーラブルで高可用性のマルチテナントログ集約システム。ログデータの効率的な集約と保存を実現します。

## 概要

### このドキュメントの目的
このロールは、Grafana Lokiをrootlessコンテナとしてデプロイし、ログ集約サービスを提供します。Ansible roleによる自動設定と手動での設定手順の両方に対応しています。

### 実現される機能
- ログデータの集約と長期保存
- 効率的なログインデックスとクエリ機能
- Grafanaとの統合によるログ可視化
- 保持ポリシーによる自動ログ管理
- Rootlessコンテナによる安全な運用

## 要件と前提条件

### 共通要件
- OS: Ubuntu (focal, jammy), Debian (buster, bullseye), RHEL/CentOS (8, 9)
- Podmanがインストールされていること
- systemdによるユーザーサービス管理が可能であること
- ポート3100が利用可能であること

### Ansible固有の要件
- Ansible 2.9以上
- 制御ノードからターゲットホストへのSSH接続が可能であること

### 手動設定の要件
- sudo権限を持つユーザーアカウント
- Podman 3.0以上がインストールされていること

## 設定方法

### 方法1: Ansible Roleを使用

#### ロール変数

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

#### 依存関係
- [podman_rootless_quadlet_base](../../../infrastructure/container/podman_rootless_quadlet_base/README.md)ロールを内部的に使用

#### タグとハンドラー
- ハンドラー:
  - `reload systemd user daemon`: systemdユーザーデーモンをリロード
  - `restart loki`: Lokiサービスを再起動

#### 使用例

基本的な使用例:
```yaml
- hosts: monitoring_servers
  roles:
    - role: services.monitoring.loki
```

カスタム設定を含む例:
```yaml
- hosts: monitoring_servers
  roles:
    - role: services.monitoring.loki
      vars:
        loki_user: "monitoring"
        loki_container_port: 3100
        loki_auth_enabled: false
```

### 方法2: 手動での設定手順

#### ステップ1: 環境準備

```bash
# アプリケーション名とユーザー名を設定
APP_NAME="loki" &&
QUADLET_USER="monitoring" &&
USER_COMMENT="Grafana Loki rootless user"
```

この先の基本セットアップは、[podman_rootless_quadlet_base](../../../infrastructure/container/podman_rootless_quadlet_base/README.md)を参照してください。

#### ステップ2: ネットワーク設定

```bash
# ネットワークファイルの作成
if [ ! -f "/home/monitoring/.config/containers/systemd/monitoring.network" ]; then
sudo -u "monitoring" tee "/home/monitoring/.config/containers/systemd/monitoring.network" << EOF > /dev/null
[Unit]
Description=Monitoring Container Network

[Network]
Label=app=monitoring
EOF
fi
```

#### ステップ3: 設定ファイルの作成

```bash
# 設定ディレクトリの作成
sudo -u "monitoring" mkdir -p /home/monitoring/.config/loki

# Loki設定ファイルの作成
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

#### ステップ4: Quadletコンテナの設定

```bash
# データディレクトリの作成
sudo -u "monitoring" mkdir -p "/home/monitoring/.local/share/loki"

# Quadletコンテナ定義ファイルの作成
sudo -u "monitoring" tee "/home/monitoring/.config/containers/systemd/loki.container" << EOF > /dev/null
[Unit]
Description=Grafana Loki Service
After=network-online.target
Wants=network-online.target

[Container]
Image=docker.io/grafana/loki:latest
ContainerName=loki
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

#### ステップ5: サービスの起動と有効化

サービスおよびタイマーの起動と有効化については、[podman_rootless_quadlet_base](../../../infrastructure/container/podman_rootless_quadlet_base/README.md)を参照してください。

## 運用管理

### 基本操作

サービスの起動・停止・再起動などの基本的なsystemdコマンドについては、[podman_rootless_quadlet_base](../../infrastructure/container/podman_rootless_quadlet_base/README.md#基本操作)を参照してください。

```bash
# Loki固有のサービス状態確認
sudo -u monitoring systemctl --user status loki.service
```

### ログとモニタリング

ログ確認やコンテナ状態確認の基本的なコマンドは、[podman_rootless_quadlet_base](../../infrastructure/container/podman_rootless_quadlet_base/README.md#ログとモニタリング)を参照してください。

```bash
# Loki固有のサービス状態確認
wget -O - http://localhost:3100/ready

# プッシュエンドポイントの確認
wget --method=POST --header="Content-Type: application/json" --body-data='{}' http://localhost:3100/loki/api/v1/push
```

### トラブルシューティング

診断フロー:
1. サービスの状態確認
2. ログメッセージの確認
3. ネットワーク接続性の確認
4. ディスク容量の確認
5. 設定ファイルの構文確認

よくある問題と対処:
- **サービスが起動しない**: ポート競合の確認、設定ファイルの構文チェック
- **ログが保存されない**: ディスク容量とパーミッションの確認
- **クエリが失敗する**: インデックス破損の確認、保持期間の設定確認

```bash
# ポート使用状況の確認
ss -tlnp | grep 3100

# ディスク使用量の確認
df -h /home/monitoring/.local/share/loki

# 設定ファイルの構文確認
sudo -u monitoring podman run --rm -v /home/monitoring/.config/loki/loki.yaml:/loki.yaml:ro docker.io/grafana/loki:latest -config.file=/loki.yaml -verify-config
```

### メンテナンス

```bash
# データのバックアップ
sudo -u monitoring tar czf loki-backup-$(date +%Y%m%d).tar.gz -C /home/monitoring/.local/share loki

# コンテナイメージの更新
sudo -u monitoring podman pull docker.io/grafana/loki:latest
sudo -u monitoring XDG_RUNTIME_DIR=/run/user/$(id -u monitoring) systemctl --user restart loki.service

# 古いイメージのクリーンアップ
sudo -u monitoring podman image prune -f

# 古いログチャンクの手動削除（保持期間を超えたもの）
# 注意: 通常は自動的に削除されるため、手動削除は推奨されません
```

## アンインストール（手動）

```bash
# 1. サービスの停止と無効化
sudo -u monitoring XDG_RUNTIME_DIR=/run/user/$(id -u monitoring) systemctl --user stop loki.service
sudo -u monitoring XDG_RUNTIME_DIR=/run/user/$(id -u monitoring) systemctl --user disable loki.service

# 2. Quadlet設定ファイルの削除
sudo rm -f /home/monitoring/.config/containers/systemd/loki.container

# 3. systemdデーモンのリロード
sudo -u monitoring XDG_RUNTIME_DIR=/run/user/$(id -u monitoring) systemctl --user daemon-reload

# 4. コンテナとイメージの削除
sudo -u monitoring podman rm -f loki || true
sudo -u monitoring podman rmi docker.io/grafana/loki:latest || true

# 5. ネットワークの削除（他のサービスで使用していない場合）
sudo -u monitoring podman network rm monitoring || true
sudo rm -f /home/monitoring/.config/containers/systemd/monitoring.network

# 6. 設定ファイルの削除
sudo rm -rf /home/monitoring/.config/loki

# 7. データディレクトリの削除（オプション - ログデータを保持する場合はスキップ）
# 警告: この操作により全てのログデータが削除されます
# sudo rm -rf /home/monitoring/.local/share/loki

# 8. ユーザーの削除（他のサービスで使用していない場合）
# 警告: monitoringユーザーのホームディレクトリも削除されます
# sudo userdel -r monitoring
```

## 参考

- [Grafana Loki公式ドキュメント](https://grafana.com/docs/loki/latest/)
- [Loki設定リファレンス](https://grafana.com/docs/loki/latest/configuration/)
- [Podman Rootless Quadlet Base](../../infrastructure/container/podman_rootless_quadlet_base/README.md)