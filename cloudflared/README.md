# cloudflared

Cloudflare Tunnel (cloudflared) をrootless Podmanコンテナとしてsystemdシステムインスタンスでインストール・設定するロール

## 概要

このロールは、Podman Quadletを使用してcloudflaredをsystemdのシステムインスタンスで実行します。コンテナは指定されたユーザー権限で動作し（rootless）、システム起動時に自動的に開始されます。

## 要件

- Podmanがインストールされていること（`podman_install`ロールを使用）
- systemdが利用可能であること
- システムユーザーとサービスの作成にroot権限が必要なため、プレイブックレベルで`become: true`の指定が必要

## ロール変数

### 必須変数
- `cloudflared_tunnel_token`: 認証用のCloudflare Tunnelトークン

### オプション変数
- `cloudflared_container_user`: コンテナを実行するシステムユーザー（デフォルト: cloudflared）
- `cloudflared_container_group`: コンテナを実行するグループ（デフォルト: cloudflared）
- `cloudflared_container_name`: コンテナ名（デフォルト: cloudflared）
- `cloudflared_image`: 使用するコンテナイメージ（デフォルト: docker.io/cloudflare/cloudflared:latest）
- `cloudflared_systemd_dir`: systemdコンテナユニットファイルの配置場所（デフォルト: /etc/containers/systemd）
- `cloudflared_env_file`: 環境変数ファイルの配置場所（デフォルト: /etc/cloudflared/cloudflared.env）

## 実装の詳細

### Podman Quadlet システムインスタンス

このロールは以下の重要な設定でrootlessコンテナを実現しています：

1. **User=/Group=の指定**: コンテナユニットファイルの`[Service]`セクションでユーザーとグループを明示的に指定
2. **システムディレクトリの使用**: `/etc/containers/systemd/`にユニットファイルを配置
3. **SELinuxコンテキスト**: ボリュームマウントに`z`オプションを使用してSELinuxコンテキストを自動調整
4. **UserNS=keep-id**: UIDマッピングを保持してコンテナ内外でユーザーIDを一致させる

### ディレクトリ構造

- `/etc/containers/systemd/cloudflared.container`: コンテナユニットファイル
- `/etc/cloudflared/cloudflared.env`: 環境変数ファイル（トークン等）
- `/home/cloudflared/`: cloudflaredユーザーのホームディレクトリ

### セキュリティ

- cloudflaredユーザーは`/sbin/nologin`シェルを持つシステムユーザー
- 環境変数ファイルは`root:cloudflared`所有で`0640`権限
- コンテナはrootlessで実行され、最小限の権限で動作

## 依存関係

- このロールを適用する前に`podman_install`ロールが適用されている必要があります

## 使用例

```yaml
- hosts: tunnel_hosts
  become: true
  roles:
    - role: cloudflared
      vars:
        cloudflared_tunnel_token: "your-tunnel-token-here"
```

## トラブルシューティング

### サービスの状態確認
```bash
# サービスの状態を確認
systemctl status cloudflared.service

# ログを確認
journalctl -u cloudflared.service -f

# コンテナの状態を確認
podman ps -a
```

### 手動でのコンテナ起動テスト
```bash
# cloudflaredユーザーとして実行
sudo -u cloudflared podman run --rm \
  --env-file=/etc/cloudflared/cloudflared.env \
  docker.io/cloudflare/cloudflared:latest tunnel run
```

## ライセンス

BSD

## 作者情報

ansible-homeプロジェクトの一部として作成