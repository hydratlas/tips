# k3s

k3s（軽量Kubernetes）をシンプルな方法でインストールします。

## 概要

このロールは、k3sの公式インストールスクリプトを使用してk3sをインストールします。

## 実行される処理

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

- k3sのデフォルト設定でインストールされるため、カスタマイズが必要な場合は手動で設定ファイルを編集する必要があります
