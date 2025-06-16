# podman_docker

podman-docker互換性パッケージのインストールと設定を行うロール

## 概要

このロールは、既存のDockerコマンドをPodmanで実行できるようにするpodman-docker互換性パッケージをインストールし、コンテナレジストリの設定を行います。RHELベースとDebianベースの両方のディストリビューションをサポートします。

## 要件

- rootまたはsudo権限
- Podmanが事前にインストールされていること（`podman`ロールを先に実行）
- サポートされるOS：RHEL/CentOS/Fedora、Debian/Ubuntu
- プレイブックレベルで`become: true`の指定が必要

## ロール変数

なし（OSファミリーに基づいて自動的にパッケージマネージャーを選択）

## 依存関係

- `podman`ロールが事前に適用されている必要があります

## 使用例

```yaml
- hosts: container_hosts
  become: true
  roles:
    - podman
    - podman-docker
```

## 設定内容

- podman-docker互換性パッケージのインストール
  - RedHat系: dnfを使用
  - Debian系: aptを使用（--no-install-recommendsオプション付き）
- unqualified-search-registriesの設定（docker.ioをデフォルトレジストリに設定）
- `/etc/containers/nodocker`マーカーファイルの作成

## 手動での設定手順

以下の手順により、podman-docker互換性環境を手動で設定できます：

### 1. podman-dockerパッケージのインストール

#### Debian/Ubuntu系の場合：

```bash
# パッケージのインストール（推奨パッケージを除外）
sudo apt-get update
sudo apt-get install -y --no-install-recommends podman-docker
```

#### RHEL/CentOS/Fedora系の場合：

```bash
# パッケージのインストール
sudo dnf install -y podman-docker
```

### 2. コンテナレジストリの設定

Docker Hubをデフォルトのレジストリとして設定します：

```bash
# registries.confファイルが存在しない場合は作成
sudo touch /etc/containers/registries.conf

# 既存の設定をバックアップ
sudo cp /etc/containers/registries.conf /etc/containers/registries.conf.bak

# unqualified-search-registriesの設定を追加または更新
sudo sed -i '/^#*\s*unqualified-search-registries/d' /etc/containers/registries.conf
echo 'unqualified-search-registries = ["docker.io"]' | sudo tee -a /etc/containers/registries.conf

# ファイルの権限を設定
sudo chmod 644 /etc/containers/registries.conf
sudo chown root:root /etc/containers/registries.conf
```

### 3. nodockerマーカーファイルの作成

Dockerがインストールされていないことを示すマーカーファイルを作成します：

```bash
# nodockerファイルの作成
sudo touch /etc/containers/nodocker

# 権限の設定
sudo chmod 644 /etc/containers/nodocker
sudo chown root:root /etc/containers/nodocker
```

### 4. インストールの確認

正しくインストールされたことを確認します：

```bash
# dockerコマンドの確認（podmanへのシンボリックリンク）
which docker
# 出力例: /usr/bin/docker

# シンボリックリンクの確認
ls -la /usr/bin/docker
# 出力例: lrwxrwxrwx 1 root root 15 Jan 1 12:00 /usr/bin/docker -> /usr/bin/podman

# バージョンの確認
docker --version
# 出力例: podman version 4.x.x

# レジストリ設定の確認
grep unqualified-search-registries /etc/containers/registries.conf
# 出力例: unqualified-search-registries = ["docker.io"]
```

### 5. 動作テスト

Docker互換性の動作を確認します：

```bash
# イメージのプル（dockerコマンドを使用）
docker pull alpine

# コンテナの実行
docker run --rm alpine echo "Hello from Podman with Docker compatibility!"

# イメージの一覧表示
docker images

# コンテナの一覧表示
docker ps -a
```

### 注意事項

- podman-dockerパッケージは、`docker`コマンドを`podman`へのシンボリックリンクとして提供します
- 完全なDocker互換性はありませんが、多くの基本的なDockerコマンドが動作します
- Docker Composeを使用する場合は、別途podman-composeのインストールが必要です
- systemdサービスファイルなど、Dockerに依存する設定は手動で調整が必要な場合があります