# Grafana Alloy
Grafana Alloyは、観測可能性データの収集と転送を行うためのエージェントです。このドキュメントでは、Ansible roleを使用した自動設定と手動での設定手順の両方を説明します。

## Ansible Roleによる設定
このAnsible roleは、Grafana Alloyをインストールし、systemd journalのログをLokiに転送するための設定を行います。

### 要件
- Ansible 2.9以上
- 対応OS: Ubuntu (focal, jammy), Debian (buster, bullseye), RHEL/CentOS (8, 9)

### ロール変数
| 変数名 | デフォルト値 | 説明 |
|--------|--------------|------|
| `alloy_loki_hostname` | `localhost` | Lokiサーバーのホスト名 |
| `alloy_service_enabled` | `true` | Alloyサービスの自動起動を有効にするか |
| `alloy_service_state` | `started` | Alloyサービスの状態 |

### 依存関係
なし

### Playbookの例
```yaml
- hosts: monitoring_servers
  roles:
    - role: services.monitoring.alloy
      vars:
        alloy_loki_hostname: "loki.example.com"
```

### タグ
このroleでは特定のタグは使用していません。

### ハンドラー
- `reload alloy`: Alloyサービスをリロード
- `restart alloy`: Alloyサービスを再起動

## トラブルシューティング
```bash
# サービスの状態確認
sudo systemctl status alloy.service

# サービスの再起動
sudo systemctl restart alloy.service

# サービスのログの確認（最新の100行）
sudo journalctl -u alloy.service --no-pager -n 100

# サービスのログの確認（リアルタイム表示）
sudo journalctl -u alloy.service -f

# 実行
sudo alloy run /etc/alloy/config.alloy
```

## 停止・削除
```bash
sudo systemctl disable --now alloy.service &&
sudo apt-get purge -y alloy
```

## 手動での設定手順
### リポジトリーの設定
#### Debian系
```bash
sudo apt-get install -y gpg &&
wget -q -O - https://apt.grafana.com/gpg.key | gpg --dearmor | sudo tee /etc/apt/keyrings/grafana.gpg > /dev/null &&
sudo tee "/etc/apt/sources.list.d/grafana.sources" > /dev/null << EOF
Types: deb
URIs: https://apt.grafana.com
Suites: stable
Components: main
Signed-By: /etc/apt/keyrings/grafana.gpg
EOF
```

#### RHEL系
```bash
curl -sS -L https://rpm.grafana.com/gpg.key | sudo rpm --import -
sudo tee /etc/yum.repos.d/grafana.repo > /dev/null << EOF
[grafana]
name=grafana
baseurl=https://rpm.grafana.com
repo_gpgcheck=1
enabled=1
gpgcheck=1
gpgkey=https://rpm.grafana.com/gpg.key
sslverify=1
sslcacert=/etc/pki/tls/certs/ca-bundle.crt
EOF
```

### インストール
`loki_hostname`の値は適宜書き換えること。`localhost`は、localhostにLokiがあるという設定である。
```bash
loki_hostname="localhost" &&
if command -v apt-get &> /dev/null; then
    sudo apt-get update &&
    sudo apt-get install -y alloy
elif command -v dnf &> /dev/null; then
    sudo dnf update &&
    sudo dnf install -y alloy
fi &&
(
sudo tee "/etc/alloy/config.alloy" > /dev/null << EOF
loki.relabel "journal" {
  forward_to = []

  rule {
    source_labels = ["__journal__systemd_unit"]
    target_label  = "unit"
  }
}

loki.source.journal "read"  {
  forward_to    = [loki.write.endpoint.receiver]
  relabel_rules = loki.relabel.journal.rules
  labels        = {component = "loki.source.journal"}
}

loki.write "endpoint" {
  endpoint {
    url = "http://${loki_hostname}:3100/loki/api/v1/push"
  }
}
EOF
) &&
sudo usermod -aG systemd-journal alloy &&
sudo systemctl reload alloy.service &&
sudo systemctl enable --now alloy.service
```
