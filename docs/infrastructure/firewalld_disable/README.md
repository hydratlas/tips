# firewalld_disable

ファイアウォール（ufwおよびfirewalld）を無効化します。

## 概要

このロールは、システムで動作している可能性のあるファイアウォール（ufwまたはfirewalld）を無効化します。k3sなどのサービスが正常に動作するために、ファイアウォールによる制限を解除する必要がある場合に使用します。

## 実行される処理

1. **ufw無効化**: ufwが存在して有効である場合、無効化します
2. **firewalld無効化**: firewalldが実行中の場合、停止して無効化します

## 要件

- rootまたはsudo権限

## ロール変数

このロールには設定可能な変数はありません。

## 依存関係

なし

## プレイブックの例

```yaml
- hosts: k3s_servers
  become: yes
  roles:
    - role: firewalld_disable
```

## 技術的な詳細

以下の処理を実行します：

```bash
# ufwが存在して有効である場合は無効化
which ufw && ufw status | grep -qv inactive && ufw disable

# firewalldが実行中の場合は無効化
systemctl status firewalld.service && systemctl disable --now firewalld.service
```

## 手動での設定手順

### ufw（Debian/Ubuntu系）の無効化

```bash
# ufwの状態を確認
sudo ufw status

# ufwを無効化
sudo ufw disable

# ufwの自動起動を無効化
sudo systemctl disable ufw
```

### firewalld（RHEL/CentOS系）の無効化

```bash
# firewalldの状態を確認
sudo systemctl status firewalld

# firewalldを停止
sudo systemctl stop firewalld

# firewalldの自動起動を無効化
sudo systemctl disable firewalld

# 設定を確認
sudo systemctl is-enabled firewalld
```

### iptables（従来のファイアウォール）の無効化

```bash
# 現在のiptablesルールを確認
sudo iptables -L -n -v

# すべてのルールをクリア
sudo iptables -F
sudo iptables -X
sudo iptables -t nat -F
sudo iptables -t nat -X
sudo iptables -t mangle -F
sudo iptables -t mangle -X

# デフォルトポリシーをACCEPTに設定
sudo iptables -P INPUT ACCEPT
sudo iptables -P FORWARD ACCEPT
sudo iptables -P OUTPUT ACCEPT
```

## 注意事項

- **セキュリティ警告**: ファイアウォールを無効化すると、システムが外部からの攻撃に対して脆弱になります
- このロールは開発環境や信頼できる内部ネットワークでの使用を想定しています
- 本番環境では、必要なポートのみを開放する適切なファイアウォール設定を推奨します
- k3sなどのコンテナオーケストレーションツールを使用する際に、ファイアウォールによる通信制限を回避するために使用されることを想定しています
