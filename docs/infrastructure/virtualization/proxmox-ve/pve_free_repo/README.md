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

## 手動での設定手順

以下の手順でProxmox VEのリポジトリを無料版に切り替えることができます：

1. エンタープライズリポジトリファイルをバックアップ：
```bash
# PVEエンタープライズリポジトリのバックアップ
mv /etc/apt/sources.list.d/pve-enterprise.list /etc/apt/sources.list.d/pve-enterprise.list.bak

# Cephリポジトリのバックアップ（存在する場合）
mv /etc/apt/sources.list.d/ceph.list /etc/apt/sources.list.d/ceph.list.bak
```

2. PVE no-subscriptionリポジトリの設定：
```bash
# PVE no-subscriptionリポジトリファイルを作成
cat > /etc/apt/sources.list.d/pve-no-subscription.sources << 'EOF'
Types: deb
URIs: http://download.proxmox.com/debian/pve
Suites: $(grep -oP '(?<=^VERSION_CODENAME=).+' /etc/os-release | tr -d '\"')
Components: pve-no-subscription
EOF
```

3. Ceph no-subscriptionリポジトリの設定：
```bash
# Ceph no-subscriptionリポジトリファイルを作成（Cephを使用する場合）
cat > /etc/apt/sources.list.d/ceph.sources << 'EOF'
Types: deb
URIs: http://download.proxmox.com/debian/ceph-reef
Suites: $(grep -oP '(?<=^VERSION_CODENAME=).+' /etc/os-release | tr -d '\"')
Components: no-subscription
EOF
```

4. パッケージリストの更新：
```bash
# リポジトリ情報を更新
apt-get update
```

注意事項：
- Cephのバージョンは必要に応じて変更してください（ceph-quincy、ceph-reef、ceph-squidなど）
- 無料リポジトリは本番環境での使用はサポートされていません