# Grafana

メトリクスとログの可視化プラットフォーム

## 概要

### このドキュメントの目的
このロールは、Grafanaをrootlessコンテナとしてデプロイし、PrometheusとLokiのデータソースを自動設定します。Ansible自動設定と手動設定の両方の方法に対応しています。

### 実現される機能
- Grafanaの可視化プラットフォームの構築
- Rootless Podman Quadletによる安全なコンテナ実行
- PrometheusとLokiデータソースの自動設定
- 匿名アクセスでのViewer権限付与
- コンテナイメージの自動更新

## 要件と前提条件

### 共通要件
- 対応OS: Ubuntu (focal, jammy), Debian (buster, bullseye), RHEL/CentOS (8, 9)
- Podmanがインストールされていること
- systemdがインストールされていること
- ネットワーク接続（コンテナイメージの取得用）

### Ansible固有の要件
- Ansible 2.9以上
- 制御ノードから対象ホストへのSSH接続
- 対象ホストでのsudo権限

### 手動設定の要件
- rootまたはsudo権限
- 基本的なLinuxコマンドの知識

## 設定方法

### 方法1: Ansible Roleを使用

#### ロール変数

| 変数名 | デフォルト値 | 説明 |
|--------|--------------|------|
| `grafana_user` | `monitoring` | Grafanaを実行するユーザー名 |
| `grafana_user_comment` | `Grafana rootless user` | ユーザーのコメント |
| `grafana_app_name` | `grafana` | アプリケーション名（設定ディレクトリ名に使用） |
| `grafana_container_image` | `docker.io/grafana/grafana-oss:latest` | 使用するコンテナイメージ |
| `grafana_container_port` | `3000` | Grafanaのリスニングポート |
| `grafana_network_name` | `monitoring.network` | 使用するコンテナネットワーク |
| `grafana_service_description` | `Grafana Service` | サービスの説明 |
| `grafana_service_restart` | `always` | コンテナの再起動ポリシー |
| `grafana_service_restart_sec` | `5` | 再起動間隔（秒） |
| `grafana_admin_user` | `admin` | 管理者ユーザー名 |
| `grafana_admin_password` | 自動生成 | 管理者パスワード（24文字のランダム文字列） |
| `grafana_allow_sign_up` | `false` | ユーザー登録を許可するか |
| `grafana_allow_org_create` | `false` | 組織の作成を許可するか |
| `grafana_anonymous_enabled` | `true` | 匿名アクセスを有効にするか |
| `grafana_anonymous_org_role` | `Viewer` | 匿名ユーザーのロール |

#### 依存関係
なし

#### タグとハンドラー

**ハンドラー:**
- `reload systemd user daemon`: systemdユーザーデーモンをリロード
- `restart grafana`: Grafanaサービスを再起動

**タグ:**
このroleでは特定のタグは使用していません。

#### 使用例

基本的な使用例：
```yaml
- hosts: monitoring_servers
  roles:
    - role: services.monitoring.grafana
      vars:
        grafana_user: "monitoring"
        grafana_container_port: 3000
```

カスタムポートとイメージを使用する例：
```yaml
- hosts: monitoring_servers
  roles:
    - role: services.monitoring.grafana
      vars:
        grafana_user: "monitoring"
        grafana_container_port: 3001
        grafana_container_image: "docker.io/grafana/grafana-oss:10.2.0"
```

### 方法2: 手動での設定手順

#### ステップ1: 環境準備

```bash
# アプリケーション名とユーザー名を設定
APP_NAME="grafana" &&
QUADLET_USER="monitoring" &&
USER_COMMENT="Grafana rootless user"
```

この先は、[podman_rootless_quadlet_base](../../../infrastructure/container/podman_rootless_quadlet_base/README.md)を参照してユーザー作成とディレクトリ準備を行います。

#### ステップ2: インストール

Podmanのインストールは各ディストリビューションのパッケージマネージャーを使用してください。

#### ステップ3: 設定

##### ネットワークファイルの作成

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

##### 環境変数ファイルの作成

```bash
# 管理者パスワードの生成
password="$(tr -dc 'A-Za-z0-9' < /dev/urandom | head -c 24)"

# 環境変数ファイルの作成
sudo -u monitoring tee /home/monitoring/.config/grafana/grafana.env << EOF > /dev/null
GF_SECURITY_ADMIN_USER=admin
GF_SECURITY_ADMIN_PASSWORD=${password}
GF_USERS_ALLOW_SIGN_UP=false
GF_USERS_ALLOW_ORG_CREATE=false
GF_AUTH_ANONYMOUS_ENABLED=true
GF_AUTH_ANONYMOUS_ORG_ROLE=Viewer
EOF

# パーミッションの設定
sudo chmod 600 /home/monitoring/.config/grafana/grafana.env
sudo chown monitoring:monitoring /home/monitoring/.config/grafana/grafana.env

# パスワードの表示
echo "Grafana admin password: ${password}"
```

##### データソース設定ファイルの作成

```bash
# データソースディレクトリの作成
sudo -u monitoring mkdir -p /home/monitoring/.config/grafana/provisioning/datasources

# Prometheusデータソース
sudo -u monitoring tee /home/monitoring/.config/grafana/provisioning/datasources/prometheus.yaml << EOF > /dev/null
apiVersion: 1
datasources:
  - name: prometheus
    type: prometheus
    access: proxy
    url: http://victoria-metrics:8428/
    isDefault: true
EOF

# Lokiデータソース
sudo -u monitoring tee /home/monitoring/.config/grafana/provisioning/datasources/loki.yaml << EOF > /dev/null
apiVersion: 1
datasources:
  - name: loki
    type: loki
    access: proxy
    url: http://loki:3100/
EOF
```

##### Podman Quadletコンテナファイルの作成

```bash
# データディレクトリの作成
sudo -u monitoring mkdir -p /home/monitoring/.local/share/grafana

# Quadletコンテナ定義ファイルの作成
sudo -u monitoring tee /home/monitoring/.config/containers/systemd/grafana.container << 'EOF' > /dev/null
[Unit]
Description=Grafana Service
Wants=victoria-metrics.service
Wants=loki.service
After=victoria-metrics.service
After=loki.service

[Container]
Image=docker.io/grafana/grafana-oss:latest
ContainerName=grafana
Network=monitoring.network
EnvironmentFile=/home/monitoring/.config/grafana/grafana.env
AutoUpdate=registry
LogDriver=journald
UserNS=keep-id
NoNewPrivileges=true
PublishPort=3000:3000
Volume=/home/monitoring/.local/share/grafana:/var/lib/grafana:Z
Volume=/home/monitoring/.config/grafana/provisioning/datasources:/etc/grafana/provisioning/datasources:z
Volume=/etc/localtime:/etc/localtime:ro,z

[Service]
Restart=always
RestartSec=5

[Install]
WantedBy=default.target
EOF

# パーミッションの設定
sudo chmod 644 /home/monitoring/.config/containers/systemd/grafana.container
```

#### ステップ4: 起動と有効化

[podman_rootless_quadlet_base](../../../infrastructure/container/podman_rootless_quadlet_base/README.md)を参照してサービスを起動します。

## 運用管理

### 基本操作

サービスの起動・停止・再起動などの基本的なsystemdコマンドについては、[podman_rootless_quadlet_base](../../infrastructure/container/podman_rootless_quadlet_base/README.md#基本操作)を参照してください。

```bash
# Grafana固有の操作例
sudo -u monitoring systemctl --user status grafana.service
```

### ログとモニタリング

ログ確認やコンテナ状態確認の基本的なコマンドは、[podman_rootless_quadlet_base](../../infrastructure/container/podman_rootless_quadlet_base/README.md#ログとモニタリング)を参照してください。

```bash
# Grafana固有のログ確認
sudo -u monitoring journalctl --user -u grafana.service --no-pager -n 100

# コンテナの詳細情報
sudo -u monitoring podman inspect grafana
```

### トラブルシューティング

#### サービスが起動しない場合

1. 設定ファイルの確認
```bash
# 環境変数ファイルの確認
sudo cat /home/monitoring/.config/grafana/grafana.env

# Quadletファイルの確認
sudo cat /home/monitoring/.config/containers/systemd/grafana.container
```

2. ポートの競合確認
```bash
sudo ss -tlnp | grep :3000
```

3. コンテナイメージの確認
```bash
sudo -u monitoring podman images | grep grafana
```

#### 初期設定

1. `http://example.com:3000`にアクセス（`example.com`はインストールしたマシンのホスト名またはIPアドレス）
2. Ansible実行時に表示される管理者ユーザー名とパスワードでログイン
3. 左ペインの「Dashboards」画面で、右上の`New`ボタンから`Import`を選択
   - IDとして`1860`を入力して、`Load`を押す。データソースはPrometheusを使用する
     - [Node Exporter Full | Grafana Labs](https://grafana.com/ja/grafana/dashboards/1860-node-exporter-full/)
   - IDとして`14055`を入力して、`Load`を押す。データソースはPrometheusおよびLokiを使用する
     - [Loki stack monitoring (Promtail, Loki) | Grafana Labs](https://grafana.com/grafana/dashboards/14055-loki-stack-monitoring-promtail-loki/)

### メンテナンス

#### バックアップ

```bash
# データディレクトリのバックアップ
sudo tar -czf grafana-backup-$(date +%Y%m%d).tar.gz \
    /home/monitoring/.local/share/grafana \
    /home/monitoring/.config/grafana
```

#### アップデート

```bash
# 手動でのイメージ更新
sudo -u monitoring podman pull docker.io/grafana/grafana-oss:latest

# サービスの再起動
sudo -u monitoring XDG_RUNTIME_DIR=/run/user/$(id -u monitoring) systemctl --user restart grafana.service
```

自動更新は`podman-auto-update.timer`により定期的に実行されます。

## アンインストール（手動）

以下の手順でGrafanaを完全に削除します。

```bash
# 1. サービスの停止
sudo -u monitoring XDG_RUNTIME_DIR=/run/user/$(id -u monitoring) systemctl --user stop grafana.service

# 2. Quadletファイルの削除
sudo rm -f /home/monitoring/.config/containers/systemd/grafana.container

# 3. ネットワークファイルの削除（他のサービスが使用していない場合）
sudo rm -f /home/monitoring/.config/containers/systemd/monitoring.network

# 4. systemdデーモンのリロード
sudo -u monitoring XDG_RUNTIME_DIR=/run/user/$(id -u monitoring) systemctl --user daemon-reload

# 5. コンテナイメージの削除
sudo -u monitoring podman rmi docker.io/grafana/grafana-oss:latest

# 6. 設定ファイルとデータの削除
# 警告: この操作により、すべてのダッシュボード、ユーザー、設定が削除されます
sudo rm -rf /home/monitoring/.config/grafana
sudo rm -rf /home/monitoring/.local/share/grafana

# 7. ユーザーの削除（オプション）
# 警告: このユーザーが他のサービスでも使用されている場合は削除しないでください
# sudo loginctl disable-linger monitoring
# sudo userdel -r monitoring
```

## 参考

- [Run Grafana Docker image | Grafana documentation](https://grafana.com/docs/grafana/latest/setup-grafana/installation/docker/)
- [Podman Quadlet Documentation](https://docs.podman.io/en/latest/markdown/podman-systemd.unit.5.html)