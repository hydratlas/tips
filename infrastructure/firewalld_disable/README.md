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

## 注意事項

- このロールはファイアウォールを無効化するため、セキュリティを考慮した環境では適切なファイアウォール設定を別途行う必要があります
- k3sなどのコンテナオーケストレーションツールを使用する際に、ファイアウォールによる通信制限を回避するために使用されることを想定しています

## ライセンス

BSD

## 作成者情報

ホームインフラストラクチャ自動化のために作成されました