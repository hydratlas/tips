# podman_install

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
    - podman_install
```

## 設定内容

- OSファミリーの検出
- 適切なパッケージマネージャーを使用してPodmanをインストール
  - RedHat系: dnfを使用
  - Debian系: aptを使用