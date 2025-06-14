# pve_free_repo

このロールは、Proxmox VEのリポジトリをエンタープライズリポジトリから無料/非サブスクリプションリポジトリに設定します。

## 機能

1. エンタープライズリポジトリファイルをバックアップ
2. 以下の新しいリポジトリ設定ファイルを作成：
   - Proxmox VE no-subscriptionリポジトリ
   - Ceph no-subscriptionリポジトリ

## 変数

- `ceph_version`: 使用するCephのバージョン（デフォルト: `reef`）
  - 利用可能な値: `quincy`, `reef`, `squid`

## 使用方法

```yaml
- hosts: proxmox_hosts
  roles:
    - pve_free_repo
```