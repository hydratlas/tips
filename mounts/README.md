# mounts

ローカルファイルシステムマウント管理ロール

## 概要

このロールは、ローカルファイルシステムのマウントポイントを管理します。`/etc/fstab` エントリの作成とマウントの実行を行います。

## 要件

- rootまたはsudo権限
- マウント対象のデバイスまたはファイルシステム

## ロール変数

- `mounts`: マウント設定のリスト
  - `src`: ソースデバイスまたはファイルシステム
  - `path`: マウントポイント
  - `fstype`: ファイルシステムタイプ
  - `opts`: マウントオプション（デフォルト: defaults）
  - `state`: マウント状態（mounted/present/absent/unmounted）

## 使用例

```yaml
- hosts: all
  become: true
  vars:
    mounts:
      - src: /dev/sdb1
        path: /data
        fstype: ext4
        opts: defaults,noatime
        state: mounted
  roles:
    - mounts
```

## 設定内容

- マウントポイントディレクトリの作成
- `/etc/fstab` エントリの管理
- ファイルシステムのマウント/アンマウント