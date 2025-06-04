# cloudflared

Cloudflare Tunnel (cloudflared) をrootless Podmanコンテナとしてsystemdユーザーサービスでインストール・設定するロール

## 要件

- Podmanがインストールされていること（`podman_install`ロールを使用）
- systemdが利用可能であること
- システムユーザーとサービスの作成にroot権限が必要なため、プレイブックレベルで`become: true`の指定が必要

## ロール変数

必須変数:
- `cloudflared_tunnel_token`: 認証用のCloudflare Tunnelトークン

オプション変数:
- `cloudflared_container_user`: コンテナを実行するシステムユーザー（デフォルト: cloudflared）
- `cloudflared_container_name`: コンテナ名（デフォルト: cloudflared）
- `cloudflared_image`: 使用するコンテナイメージ（デフォルト: docker.io/cloudflare/cloudflared:latest）

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

## ライセンス

BSD

## 作者情報

ansible-homeプロジェクトの一部として作成