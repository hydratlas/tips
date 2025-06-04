# podman-docker_install

podman-docker互換性パッケージのインストールと設定を行うロール

## 概要

このロールは、既存のDockerコマンドをPodmanで実行できるようにするpodman-docker互換性パッケージをインストールし、コンテナレジストリの設定を行います。RHELベースとDebianベースの両方のディストリビューションをサポートします。

## 要件

- rootまたはsudo権限
- Podmanが事前にインストールされていること（`podman_install`ロールを先に実行）
- サポートされるOS：RHEL/CentOS/Fedora、Debian/Ubuntu
- プレイブックレベルで`become: true`の指定が必要

## ロール変数

なし（OSファミリーに基づいて自動的にパッケージマネージャーを選択）

## 依存関係

- `podman_install`ロールが事前に適用されている必要があります

## 使用例

```yaml
- hosts: container_hosts
  become: true
  roles:
    - podman_install
    - podman-docker_install
```

## 設定内容

- podman-docker互換性パッケージのインストール
  - RedHat系: dnfを使用
  - Debian系: aptを使用（--no-install-recommendsオプション付き）
- unqualified-search-registriesの設定（docker.ioをデフォルトレジストリに設定）
- `/etc/containers/nodocker`マーカーファイルの作成