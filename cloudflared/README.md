# cloudflared

Cloudflare TunnelをPodman Quadletで専用ユーザーのrootlessコンテナとして実行するAnsibleロール。

## 概要

このロールは、専用の「cloudflared」ユーザーを作成し、そのユーザーの権限でCloudflare Tunnelをrootlessコンテナとして実行します。ユーザーのホームディレクトリ（`/home/cloudflared/.config/containers/systemd/`）にQuadletファイルを配置します。

## 主な違い（cloudflared_quadletとの比較）

- **専用ユーザーでのrootlessコンテナ**: デフォルトで「cloudflared」ユーザーを作成して実行
- **ユーザーsystemdサービス**: `/etc/containers/systemd/`ではなく`/home/cloudflared/.config/containers/systemd/`を使用
- **ホームディレクトリ配置**: 設定ファイルは`/home/cloudflared/.config/cloudflared/`に配置
- **ユーザースコープ管理**: cloudflaredユーザーとして`systemctl --user`でサービスを管理

## 変数

| 変数名 | デフォルト値 | 説明 |
|--------|--------------|------|
| `cloudflared_user` | `cloudflared` | 実行ユーザー名 |
| `cloudflared_image` | `docker.io/cloudflare/cloudflared:latest` | 使用するコンテナイメージ |
| `cloudflared_token` | `""` | Cloudflare Tunnelトークン（必須） |

注: `cloudflared_config_dir`と`cloudflared_systemd_dir`は、ユーザーのホームディレクトリから自動的に生成されます。

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

## サービス管理

サービスの管理はcloudflaredユーザーで`systemctl --user`コマンドを使用します。また、このロールは自動的に`podman-auto-update.timer`を有効化し、コンテナイメージの自動更新を設定します。

```bash
# cloudflaredユーザーになる
sudo -u cloudflared -i

# サービスの状態確認
systemctl --user status cloudflared.service

# サービスの開始
systemctl --user start cloudflared.service

# サービスの停止
systemctl --user stop cloudflared.service

# サービスの再起動
systemctl --user restart cloudflared.service

# ログの確認
journalctl --user -u cloudflared.service -f
```

または、rootユーザーから直接管理する場合：

```bash
# サービスの状態確認
sudo -u cloudflared XDG_RUNTIME_DIR=/run/user/$(id -u cloudflared) systemctl --user status cloudflared.service

# ログの確認
sudo -u cloudflared XDG_RUNTIME_DIR=/run/user/$(id -u cloudflared) journalctl --user -u cloudflared.service -f

# 自動更新タイマーの状態確認
sudo -u cloudflared XDG_RUNTIME_DIR=/run/user/$(id -u cloudflared) systemctl --user status podman-auto-update.timer
```

## ディレクトリ構造

ロールは以下のディレクトリとファイルを作成します（デフォルトの場合）：

- `/home/cloudflared/` - cloudflaredユーザーのホームディレクトリ
- `/home/cloudflared/.config/cloudflared/` - 設定ディレクトリ
  - `cloudflared.env` - 環境変数ファイル（トークンを含む）
- `/home/cloudflared/.config/containers/systemd/` - Quadletディレクトリ
  - `cloudflared.container` - Podman Quadletコンテナ定義
- `/home/cloudflared/.local/share/containers/storage` - コンテナストレージ

## セキュリティ

- 専用のシステムユーザーを作成し、そのユーザーで実行
- トークンは環境変数ファイルに保存され、パーミッション600で保護されます
- コンテナは`NoNewPrivileges=true`と`ReadOnly=true`で実行されます
- 完全にrootless環境で動作し、root権限を必要としません
- ユーザーにはsubuid/subgidが自動的に割り当てられます

## 前提条件

- Podmanがインストールされていること
- systemdがインストールされていること
- loginctlコマンドが利用可能であること（systemd-loginパッケージ）