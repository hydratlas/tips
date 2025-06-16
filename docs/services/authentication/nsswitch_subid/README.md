# nsswitch_subid

NSS subuid/subgid設定ロール

## 概要

このロールは、コンテナのsubuid/subgid検索のためにNSS（Name Service Switch）を設定します。`/etc/nsswitch.conf` にSSSDをプロバイダーとして追加し、集中管理されたUID/GIDマッピングを有効にします。

## 要件

- SSSDがインストールされ設定されていること
- rootまたはsudo権限
- プレイブックレベルで`become: true`の指定が必要

## ロール変数

なし（このロールは固定の設定を適用します）

## 使用例

```yaml
- hosts: container_hosts
  become: true
  roles:
    - nsswitch_subid
```

## 設定内容

- `/etc/nsswitch.conf` の更新
- `subuid` と `subgid` エントリにSSSDプロバイダーを追加
- コンテナのユーザー名前空間マッピングを集中管理可能に

## 手動での設定手順

### 設定

```bash
# nsswitch.confのバックアップ
sudo cp /etc/nsswitch.conf /etc/nsswitch.conf.backup

# nsswitch.confの編集
sudo nano /etc/nsswitch.conf

# 以下の行を追加または更新:
# subid: sss

# 注意: 'subid: files sss' と設定するとsssが正しく動作しない場合があります

# 設定の確認
grep subid /etc/nsswitch.conf

# SELinuxコンテキストの確認（SELinuxが有効な場合）
sudo restorecon /etc/nsswitch.conf

# SSSDサービスの再起動
sudo systemctl restart sssd

# subuid/subgidの確認
getent subuid $(whoami)
getent subgid $(whoami)
```

### コンテナでの動作確認

```bash
# Podmanでのrootlessコンテナテスト
podman run --rm -it alpine:latest id

# Docker（rootless mode）でのテスト
docker run --rm -it alpine:latest id

# ユーザー名前空間のマッピング確認
podman unshare cat /proc/self/uid_map
podman unshare cat /proc/self/gid_map

# /etc/subuid と /etc/subgid の確認（ローカルファイル）
cat /etc/subuid
cat /etc/subgid
```

### トラブルシューティング

```bash
# SSSDの状態確認
sudo systemctl status sssd

# SSSDのsubidプロバイダー確認
sudo sssctl config-check

# NSS設定のテスト
getent passwd
getent group

# SSSDのログ確認（デバッグ）
sudo journalctl -u sssd -f

# キャッシュのクリア
sudo sss_cache -E

# 手動でのsubuid/subgid確認
id -u
id -g
```

### 注意事項

- この設定はrootlessコンテナの動作に影響します
- SSSDが正しく設定されている必要があります
- FreeIPAサーバー側でsubuid/subgidの範囲が設定されている必要があります
- ローカルの/etc/subuidと/etc/subgidファイルよりSSSDの設定が優先されます