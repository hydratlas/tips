# cloudflared

Cloudflare Tunnel (cloudflared) をk3s上のコンテナとしてデプロイするロール

## 要件

### Ansibleコントロールノードの要件

- `kubernetes.core` Ansibleコレクションがインストールされていること

### Ansibleターゲットノードの要件

- k3sクラスターがインストールされ、稼働していること
- k3sマスターノードであること（k3s APIサーバーへのアクセスが必要）
- kubeconfigファイルが適切に設定されていること（通常は`/etc/rancher/k3s/k3s.yaml`）
- このロールは`become: true`で実行される必要があります（kubeconfigファイルへのアクセスのため）

## ロール変数

### 必須変数

- `cloudflared_tunnel_token`: Cloudflare Tunnelトークン（vaultに保存することを推奨）

### オプション変数

- `cloudflared_namespace`: cloudflared用のKubernetesネームスペース（デフォルト: `cloudflared`）
- `cloudflared_deployment_name`: デプロイメント名（デフォルト: `cloudflared`）
- `cloudflared_secret_name`: トークンを含むシークレット名（デフォルト: `cloudflared-tunnel-token`）
- `cloudflared_replicas`: レプリカ数（デフォルト: `1`）
- `cloudflared_image`: 使用するコンテナイメージ（デフォルト: `docker.io/cloudflare/cloudflared:latest`）

### リソース制限

- `cloudflared_memory_limit`: メモリ上限（デフォルト: `128Mi`）
- `cloudflared_cpu_limit`: CPU上限（デフォルト: `100m`）
- `cloudflared_memory_request`: メモリ要求（デフォルト: `64Mi`）
- `cloudflared_cpu_request`: CPU要求（デフォルト: `50m`）

## 依存関係

- 事前にk3sロールが適用されている必要があります

## プレイブックの例

```yaml
- hosts: k3s_masters
  roles:
    - role: cloudflared
      vars:
        cloudflared_tunnel_token: "{{ vault_cloudflared_tunnel_token }}"
```

または、k3sマスターノード上で直接実行する場合：

```yaml
- hosts: localhost
  connection: local
  roles:
    - role: cloudflared
      vars:
        cloudflared_tunnel_token: "{{ vault_cloudflared_tunnel_token }}"
```

## 備考

- デプロイメントは最小権限で実行され、読み取り専用のルートファイルシステムを使用
- コンテナは非rootユーザー（UID 65532）として実行
- コンテナ内での自動更新は無効化