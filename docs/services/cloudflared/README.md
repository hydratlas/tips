# cloudflared

Cloudflare TunnelをPodman Quadletで専用ユーザーのrootlessコンテナとして実行するAnsibleロール。

## 前提条件

- Podmanがインストールされていること
- systemdがインストールされていること
- loginctlコマンドが利用可能であること（systemd-loginパッケージ）

## 設定内容
- 非特権ユーザーが ICMP Echo（ping）を実行可能にするカーネルパラメータを設定
- Cloudflare Tunnelのトークンは環境変数ファイルに保存され、パーミッション600で保護
- コンテナは`NoNewPrivileges=true`と`ReadOnly=true`で実行
- [podman_rootless_quadlet_base](../../infrastructure/container/podman_rootless_quadlet_base/README.md)を呼び出して設定
  - 専用のユーザーを作成
  - Lingering有効化
  - 必要なディレクトリ構造の作成
  - コンテナイメージの自動更新を設定

## 変数

| 変数名 | デフォルト値 | 説明 |
|--------|--------------|------|
| `cloudflared_user` | `cloudflared` | 実行ユーザー名 |
| `cloudflared_image` | `docker.io/cloudflare/cloudflared:latest` | 使用するコンテナイメージ |
| `cloudflared_token` | `""` | Cloudflare Tunnelトークン（必須） |

注: `cloudflared_config_dir`と`cloudflared_systemd_dir`は、ユーザーのホームディレクトリから自動的に生成されます。

## ディレクトリ構造

ロールは以下のディレクトリとファイルを作成します（デフォルトの場合）：

- `/home/cloudflared/` - cloudflaredユーザーのホームディレクトリ
- `/home/cloudflared/.config/cloudflared/` - 設定ディレクトリ
  - `cloudflared.env` - 環境変数ファイル（トークンを含む）
- `/home/cloudflared/.config/containers/systemd/` - Quadletディレクトリ
  - `cloudflared.container` - Podman Quadletコンテナ定義
- `/home/cloudflared/.local/share/containers/storage` - コンテナストレージ

## 使用例

```yaml
- hosts: myhost
  roles:
    - role: cloudflared
      vars:
        cloudflared_token: "your-tunnel-token-here"
```

カスタムユーザー名を使用する場合：

```yaml
- hosts: myhost
  roles:
    - role: cloudflared
      vars:
        cloudflared_user: "tunnel-user"
        cloudflared_token: "your-tunnel-token-here"
```

## トラブルシューティング
以下のcloudflared固有のコマンド以外は、[podman_rootless_quadlet_base](../../infrastructure/container/podman_rootless_quadlet_base/README.md)を参照。

```bash
# コンテナ内のトンネルステータスの確認
sudo -u cloudflared podman exec cloudflared cloudflared tunnel info

# コンテナイメージの手動更新
sudo -u cloudflared podman pull docker.io/cloudflare/cloudflared:latest &&
sudo -u cloudflared XDG_RUNTIME_DIR=/run/user/$(id -u cloudflared) systemctl --user restart cloudflared.service

# 環境変数ファイルの削除
sudo rm "/home/cloudflared/.config/cloudflared/cloudflared.env"
```

## 手動での設定手順

### 1. 準備
```bash
# アプリケーション名とユーザー名を設定
APP_NAME="cloudflared"
QUADLET_USER="cloudflared"
USER_COMMENT="Cloudflare Tunnel rootless user"
```
この先は、[podman_rootless_quadlet_base](../../infrastructure/container/podman_rootless_quadlet_base/README.md)を参照。

### 2. Quadletファイルなどの配置
#### 非特権ユーザーが ICMP Echo（ping）を実行可能にするカーネルパラメータの設定

```bash
# sysctlでping権限の設定
sudo tee /etc/sysctl.d/99-ping-group-range.conf << 'EOF' > /dev/null
net.ipv4.ping_group_range=0 2147483647
EOF

# sysctl設定のリロード
sudo sysctl --system
```

#### 環境変数ファイルの作成
```bash
# Cloudflare Tunnelトークンを設定（実際のトークンに置き換える）
TUNNEL_TOKEN="your-tunnel-token-here"

# 環境変数ファイルの作成
sudo -u cloudflared tee /home/cloudflared/.config/cloudflared/cloudflared.env << EOF > /dev/null
TUNNEL_TOKEN=${TUNNEL_TOKEN}
NO_AUTOUPDATE=true
EOF

# パーミッションの設定
sudo chmod 600 /home/cloudflared/.config/cloudflared/cloudflared.env
sudo chown cloudflared:cloudflared /home/cloudflared/.config/cloudflared/cloudflared.env
```

#### Podman Quadletコンテナファイルの作成
```bash
# Quadletコンテナ定義ファイルの作成
sudo -u cloudflared tee /home/cloudflared/.config/containers/systemd/cloudflared.container << 'EOF' > /dev/null
[Unit]
Description=Cloudflare Tunnel Service
After=network-online.target
Wants=network-online.target

[Container]
Image=docker.io/cloudflare/cloudflared:latest
ContainerName=cloudflared
AutoUpdate=registry
LogDriver=journald
EnvironmentFile=%h/.config/cloudflared/cloudflared.env
Exec=tunnel run
NoNewPrivileges=true
ReadOnly=true

[Service]
Restart=always
RestartSec=5

[Install]
WantedBy=default.target
EOF

# パーミッションの設定
sudo chmod 644 /home/cloudflared/.config/containers/systemd/cloudflared.container
sudo chown cloudflared:cloudflared /home/cloudflared/.config/containers/systemd/cloudflared.container
```

### 3. サービスおよびタイマーの起動と有効化
[podman_rootless_quadlet_base](../../infrastructure/container/podman_rootless_quadlet_base/README.md)を参照。
