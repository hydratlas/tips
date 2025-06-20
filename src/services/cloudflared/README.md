# cloudflared_container
Cloudflare Tunnelを実行

## 概要
### このドキュメントの目的
このドキュメントは、Cloudflare Tunnelをクライアントサイドに一般的なパッケージとしてインストールし、実行するための設定を提供します。手動設定に対応しています。

### 実現される機能
- Cloudflare Tunnelによるセキュアなリモートアクセス
- パッケージの自動更新

## 要件と前提条件
### 共通要件
- 対応OS: Debian系, RHEL系
- ネットワーク接続
- rootまたはsudo権限
- 基本的なLinuxコマンドの知識

## 設定方法
###  手動での設定手順
#### ステップ1: 環境準備（リポジトリの設定）
**Debian系の場合：**
```bash
# GPGキーのインポート
wget -O - https://pkg.cloudflare.com/cloudflare-main.gpg | gpg --dearmor | sudo tee /etc/apt/keyrings/cloudflare-main.gpg > /dev/null

# GPGキーのインポートに時間がかかるとき（IPv4接続に限定）
wget -4 -O - https://pkg.cloudflare.com/cloudflare-main.gpg | gpg --dearmor | sudo tee /etc/apt/keyrings/cloudflare-main.gpg > /dev/null

# リポジトリの追加
VERSION_CODENAME="$(grep -oP '(?<=^VERSION_CODENAME=).+' /etc/os-release | tr -d '\"')" &&
sudo tee "/etc/apt/sources.list.d/cloudflared.sources" > /dev/null << EOF
Types: deb
URIs: https://pkg.cloudflare.com/cloudflared
Suites: ${VERSION_CODENAME}
Components: main
Signed-By: /etc/apt/keyrings/cloudflare-main.gpg
EOF

# パッケージリストの更新
sudo apt-get update
```

**RHEL系の場合：**
```bash
# リポジトリの追加
sudo dnf config-manager --add-repo https://pkg.cloudflare.com/cloudflared-ascii.repo

# リポジトリキャッシュの更新
sudo dnf makecache
```

#### ステップ2: インストール
```bash
# Debian系
sudo apt-get install -y cloudflared

# RHEL系
sudo dnf install -y cloudflared
```

## 運用管理
```bash
# バージョン確認
cloudflared version
```

## アンインストール（手動）
以下の手順でCloudflaredを完全に削除します。

### サービスのアンインストール
サービスをインストールしている場合のみ実行します。
```bash
# cloudflaredサービスのアンインストール
sudo cloudflared service uninstall

# systemdデーモンのリロード
sudo systemctl daemon-reload
```

### パッケージとリポジトリの削除
**Debian系の場合：**
```bash
# 1. cloudflaredパッケージの削除
sudo apt-get remove --purge -y cloudflared

# 2. 不要な依存関係の削除
sudo apt-get autoremove -y

# 3. リポジトリの削除
sudo rm -f /etc/apt/sources.list.d/cloudflared.sources

# 4. GPGキーの削除
sudo rm -f /etc/apt/keyrings/cloudflare-main.gpg

# 5. パッケージリストの更新
sudo apt-get update
```

**RHEL系の場合：**
```bash
# 1. cloudflaredパッケージの削除
sudo dnf remove -y cloudflared

# 2. 不要な依存関係の削除
sudo dnf autoremove -y

# 3. リポジトリの削除
sudo rm -f /etc/yum.repos.d/cloudflared-ascii.repo

# 4. リポジトリキャッシュのクリア
sudo dnf clean all
```
