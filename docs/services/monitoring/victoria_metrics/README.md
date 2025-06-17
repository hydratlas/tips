# VictoriaMetrics

高性能で費用対効果の高い時系列データベース。Prometheusと互換性があり、長期保存に最適化されています。

## 概要

### このドキュメントの目的
このロールは、VictoriaMetrics（シングルノード版）をrootlessコンテナとしてデプロイする機能を提供します。Ansible roleによる自動設定と手動での設定手順の両方に対応しています。

### 実現される機能
- Prometheusと互換性のある時系列データベースの提供
- メトリクスデータの長期保存
- 高速なクエリ処理とデータ圧縮
- Rootlessコンテナによる安全な運用
- Podman Quadletによる自動起動と管理

## 要件と前提条件

### 共通要件
- OS: Ubuntu (focal, jammy), Debian (buster, bullseye), RHEL/CentOS (8, 9)
- Podmanがインストールされていること
- systemdによるユーザーサービス管理が可能であること
- ポート8428が利用可能であること

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

#### 依存関係
- [podman_rootless_quadlet_base](../../../infrastructure/container/podman_rootless_quadlet_base/README.md)ロールを内部的に使用

#### タグとハンドラー
- ハンドラー:
  - `reload systemd user daemon`: systemdユーザーデーモンをリロード
  - `restart victoria_metrics`: VictoriaMetricsサービスを再起動

#### 使用例

基本的な使用例:
```yaml
- hosts: monitoring_servers
  roles:
    - role: services.monitoring.victoria_metrics
```

カスタムスクレイプ設定を含む例:
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

### 方法2: 手動での設定手順

#### ステップ1: 環境準備

```bash
# アプリケーション名とユーザー名を設定
APP_NAME="victoria-metrics" &&
QUADLET_USER="monitoring" &&
USER_COMMENT="VictoriaMetrics rootless user"
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
sudo -u monitoring mkdir -p /home/monitoring/.config/prometheus

# Prometheus互換設定ファイルの作成
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

#### ステップ4: Quadletコンテナの設定

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

#### ステップ5: サービスの起動と有効化

サービスおよびタイマーの起動と有効化については、[podman_rootless_quadlet_base](../../../infrastructure/container/podman_rootless_quadlet_base/README.md)を参照してください。

## 運用管理

### 基本操作

サービスの起動・停止・再起動などの基本的なsystemdコマンドについては、[podman_rootless_quadlet_base](../../infrastructure/container/podman_rootless_quadlet_base/README.md#基本操作)を参照してください。

```bash
# VictoriaMetrics固有のサービス状態確認
sudo -u monitoring systemctl --user status victoria-metrics.service
```

### ログとモニタリング

ログ確認やコンテナ状態確認の基本的なコマンドは、[podman_rootless_quadlet_base](../../infrastructure/container/podman_rootless_quadlet_base/README.md#ログとモニタリング)を参照してください。

```bash
# VictoriaMetrics固有のメトリクスエンドポイント確認
curl http://localhost:8428/metrics
```

### トラブルシューティング

診断フロー:
1. サービスの状態確認
2. ログメッセージの確認
3. ネットワーク接続性の確認
4. ディスク容量の確認

よくある問題と対処:
- **サービスが起動しない**: ポート競合の確認、設定ファイルの構文チェック
- **データが保存されない**: ディスク容量とパーミッションの確認
- **メトリクスが収集されない**: スクレイプ設定とターゲットの到達性確認

```bash
# ポート使用状況の確認
ss -tlnp | grep 8428

# 設定ファイルの構文確認
sudo -u monitoring podman run --rm -v /home/monitoring/.config/prometheus/prometheus.yml:/etc/prometheus.yml:ro docker.io/victoriametrics/victoria-metrics:latest -promscrape.config=/etc/prometheus.yml -promscrape.config.dryRun

# ディスク使用量の確認
df -h /home/monitoring/.local/share/victoria-metrics-data
```

### メンテナンス

```bash
# データのバックアップ
sudo -u monitoring tar czf victoria-metrics-backup-$(date +%Y%m%d).tar.gz -C /home/monitoring/.local/share victoria-metrics-data

# コンテナイメージの更新
sudo -u monitoring podman pull docker.io/victoriametrics/victoria-metrics:latest
sudo -u monitoring XDG_RUNTIME_DIR=/run/user/$(id -u monitoring) systemctl --user restart victoria-metrics.service

# 古いイメージのクリーンアップ
sudo -u monitoring podman image prune -f

# 設定変更後の反映
sudo -u monitoring XDG_RUNTIME_DIR=/run/user/$(id -u monitoring) systemctl --user daemon-reload
sudo -u monitoring XDG_RUNTIME_DIR=/run/user/$(id -u monitoring) systemctl --user restart victoria-metrics.service
```

## アンインストール（手動）

```bash
# 1. サービスの停止と無効化
sudo -u monitoring XDG_RUNTIME_DIR=/run/user/$(id -u monitoring) systemctl --user stop victoria-metrics.service
sudo -u monitoring XDG_RUNTIME_DIR=/run/user/$(id -u monitoring) systemctl --user disable victoria-metrics.service

# 2. Quadlet設定ファイルの削除
sudo rm -f /home/monitoring/.config/containers/systemd/victoria-metrics.container

# 3. systemdデーモンのリロード
sudo -u monitoring XDG_RUNTIME_DIR=/run/user/$(id -u monitoring) systemctl --user daemon-reload

# 4. コンテナとイメージの削除
sudo -u monitoring podman rm -f victoria-metrics || true
sudo -u monitoring podman rmi docker.io/victoriametrics/victoria-metrics:latest || true

# 5. ネットワークの削除（他のサービスで使用していない場合）
sudo -u monitoring podman network rm monitoring || true
sudo rm -f /home/monitoring/.config/containers/systemd/monitoring.network

# 6. 設定ファイルの削除
sudo rm -rf /home/monitoring/.config/prometheus

# 7. データディレクトリの削除（オプション - データを保持する場合はスキップ）
# 警告: この操作により全てのメトリクスデータが削除されます
# sudo rm -rf /home/monitoring/.local/share/victoria-metrics-data

# 8. ユーザーの削除（他のサービスで使用していない場合）
# 警告: monitoringユーザーのホームディレクトリも削除されます
# sudo userdel -r monitoring
```

## 参考

- [VictoriaMetrics公式ドキュメント](https://docs.victoriametrics.com/)
- [VictoriaMetrics GitHubリポジトリ](https://github.com/VictoriaMetrics/VictoriaMetrics)
- [Prometheusでinstance名をホスト名にしたい - Qiita](https://qiita.com/fkshom/items/bafb2160e2c9ca8ded38)