# podman

Podmanコンテナランタイムインストールロール

## 概要

このロールは、Podmanコンテナランタイムをインストールします。RHELベースとDebianベースの両方のディストリビューションをサポートします。

## 要件

- rootまたはsudo権限
- サポートされるOS：RHEL/CentOS/Fedora、Debian/Ubuntu
- プレイブックレベルで`become: true`の指定が必要

## ロール変数

なし（OSファミリーに基づいて自動的にパッケージマネージャーを選択）

## 使用例

```yaml
- hosts: container_hosts
  become: true
  roles:
    - podman
```

## 設定内容

- OSファミリーの検出
- 適切なパッケージマネージャーを使用してPodmanをインストール
  - RedHat系: dnfを使用
  - Debian系: aptを使用

## 手動での設定手順

### Debian/Ubuntu系でのインストール

```bash
# パッケージリストを更新
sudo apt-get update

# Podmanをインストール
sudo apt-get install -y podman
```

### RHEL/CentOS/Fedora系でのインストール

```bash
# Podmanをインストール
sudo dnf install -y podman
```

### インストール後の確認

```bash
# Podmanのバージョンを確認
podman version

# システム情報を表示
podman info

# テストコンテナを実行
podman run docker.io/hello-world:latest
```

### 追加の確認

```bash
# レジストリの設定を確認
cat /etc/containers/registries.conf

# ストレージ設定を確認
cat /etc/containers/storage.conf
```