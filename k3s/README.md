# k3s

k3s（軽量Kubernetes）をシンプルな方法でインストールします。

## 概要

このロールは、k3sの公式インストールスクリプトを使用してk3sをインストールします。インストール前にファイアウォール（ufwおよびfirewalld）を無効化し、k3sが正常に動作するように環境を準備します。

## 実行される処理

1. **ufw無効化**: ufwが存在して有効である場合、無効化します
2. **firewalld無効化**: firewalldが実行中の場合、停止して無効化します
3. **ダウンロードツールの確認**: 
   - wgetが存在する場合はwgetを使用
   - wgetが存在せずcurlが存在する場合はcurlを使用
   - どちらも存在しない場合はwgetをインストール（apt/dnf対応）
4. **k3sインストール**: 公式スクリプトを使用してk3sをインストールします
5. **サービス管理**: k3sサービスを開始し、自動起動を有効化します

## 要件

- インターネット接続（k3sインストールスクリプトのダウンロードに必要）
- rootまたはsudo権限

## ロール変数

このシンプル化されたバージョンでは、設定可能な変数はありません。

## 依存関係

なし

## プレイブックの例

```yaml
- hosts: k3s_servers
  become: yes
  roles:
    - role: k3s
```

## 技術的な詳細

インストールは以下のコマンドと同等の処理を実行します：

```bash
# ufwが存在して有効である場合は無効化
which ufw && ufw status | grep -qv inactive && ufw disable

# firewalldが実行中の場合は無効化
systemctl status firewalld.service && systemctl disable --now firewalld.service

# ダウンロードツールの確認とインストール
if which wget >/dev/null 2>&1; then
    # wgetが存在する場合
    wget -qO- https://get.k3s.io | sh -
elif which curl >/dev/null 2>&1; then
    # curlが存在する場合
    curl -sfL https://get.k3s.io | sh -
else
    # どちらも存在しない場合はwgetをインストール
    if which apt >/dev/null 2>&1; then
        apt update && apt install -y wget
    elif which dnf >/dev/null 2>&1; then
        dnf install -y wget
    fi
    wget -qO- https://get.k3s.io | sh -
fi
```

## 注意事項

- このロールはファイアウォールを無効化するため、セキュリティを考慮した環境では適切なファイアウォール設定を別途行う必要があります
- k3sのデフォルト設定でインストールされるため、カスタマイズが必要な場合は手動で設定ファイルを編集する必要があります

## ライセンス

BSD

## 作成者情報

ホームインフラストラクチャ自動化のために作成されました