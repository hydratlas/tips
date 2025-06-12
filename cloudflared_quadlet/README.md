# Cloudflared Quadlet ロール

このAnsibleロールは、Podman Quadletを使用してCloudflare Tunnel（cloudflared）を強化されたセキュリティ設定でデプロイします。

## 機能

- Quadletを使用してcloudflaresをPodmanコンテナとしてデプロイ
- トークンベースの簡素化された設定
- 包括的なセキュリティ強化の実装：
  - 読み取り専用のルートファイルシステム
  - CAP_NET_RAWを除くすべてのLinuxケーパビリティを削除
  - コンテナ内部でcloudflared:cloudflaredユーザーとして実行
  - 権限昇格の防止
  - ユーザー名前空間の使用
- systemdサービスの自動管理
- 自動アップデートの無効化

## 要件

- ターゲットシステムにPodmanがインストールされていること
- Cloudflare Tunnelトークン

## ロール変数

### 必須変数

```yaml
cloudflared_token: "your-tunnel-token"  # Cloudflare Tunnelトークン
```

### オプション変数

```yaml
# コンテナイメージ
cloudflared_image: docker.io/cloudflare/cloudflared:latest
```

## 依存関係

- `podman` ロール

## プレイブックの例

```yaml
- hosts: tunnel_hosts
  roles:
    - role: cloudflared_quadlet
      vars:
        cloudflared_token: "eyJhIjoixxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx..."
```

## Cloudflare Tunnelトークンの取得方法

1. Cloudflareダッシュボードにログイン
2. Zero Trust > Access > Tunnelsに移動
3. 新しいトンネルを作成または既存のトンネルを選択
4. "Configure" タブでトークンをコピー

## セキュリティ機能

Quadletコンテナファイルには以下のセキュリティオプションが含まれています：

- **ReadOnly=true**: コンテナのルートファイルシステムは読み取り専用
- **NoNewPrivileges=true**: 権限昇格を防止
- **DropCapability=all**: すべてのLinuxケーパビリティを削除
- **AddCapability=CAP_NET_RAW**: rawソケット操作のためのケーパビリティのみ追加
- **User=nobody / Group=nobody**: コンテナ内部で非特権ユーザーとして実行
- **UserNS=auto**: 追加の分離のためにユーザー名前空間を使用

## 環境変数

このロールは以下の環境変数を使用します：

- `TUNNEL_TOKEN`: Cloudflare Tunnelトークン
- `NO_AUTOUPDATE=true`: 自動アップデートを無効化

## Systemdサービス

サービスはPodman Quadletによって生成され、システムサービスとして管理されます。Quadletサービスは`[Install]`セクションの`WantedBy=`によって自動的に有効化されるため、明示的な`enable`操作は不要です。

以下のコマンドで操作できます：

```bash
# サービスステータスの確認
systemctl status cloudflared.service

# ログの表示
journalctl -u cloudflared.service -f

# サービスの再起動
systemctl restart cloudflared.service

# サービスの停止
systemctl stop cloudflared.service
```
