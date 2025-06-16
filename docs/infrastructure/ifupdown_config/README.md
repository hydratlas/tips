# ifupdown_config

ネットワークインターフェース設定ロール

## 概要

このロールは、Debianスタイルのネットワーク設定（ifupdown）を管理します。`/etc/network/interfaces` ファイルを配置してネットワークインターフェースを設定します。

## 要件

- Debianベースのディストリビューション
- ifupdownパッケージ
- root権限が必要なため、プレイブックレベルで`become: true`の指定が必要

## ロール変数

- `ifupdown_config_content`: interfaces設定ファイルの内容

## 使用例

```yaml
- hosts: debian_hosts
  become: true
  vars:
    ifupdown_config_content: |
      auto lo
      iface lo inet loopback
      
      auto eth0
      iface eth0 inet dhcp
  roles:
    - ifupdown_config
```

## 設定内容

- `/etc/network/interfaces` ファイルの配置
- ネットワークインターフェースの設定

## 手動での設定手順

### Debian/Ubuntu の場合

```bash
# 現在の設定のバックアップ
sudo cp /etc/network/interfaces /etc/network/interfaces.backup

# ネットワーク設定ファイルの編集
sudo nano /etc/network/interfaces

# 基本的な設定例:
# auto lo
# iface lo inet loopback
# 
# auto eth0
# iface eth0 inet dhcp
# 
# # 静的IPの設定例
# auto eth1
# iface eth1 inet static
#     address 192.168.1.100
#     netmask 255.255.255.0
#     gateway 192.168.1.1
#     dns-nameservers 8.8.8.8 8.8.4.4

# 設定ファイルの権限設定
sudo chmod 644 /etc/network/interfaces

# ネットワーク設定の再読み込み（ifupdownパッケージが必要）
sudo ifreload -a

# または、個別のインターフェースの再起動
sudo ifdown eth0 && sudo ifup eth0

# ネットワーク状態の確認
ip addr show
ip route show
```

### 高度な設定例

```bash
# VLAN設定
sudo nano /etc/network/interfaces
# auto eth0.100
# iface eth0.100 inet static
#     address 10.100.0.10
#     netmask 255.255.255.0
#     vlan-raw-device eth0

# ブリッジ設定
# auto br0
# iface br0 inet static
#     address 192.168.1.10
#     netmask 255.255.255.0
#     bridge_ports eth0
#     bridge_stp off
#     bridge_fd 0
#     bridge_maxwait 0

# ボンディング設定
# auto bond0
# iface bond0 inet static
#     address 192.168.1.20
#     netmask 255.255.255.0
#     bond-slaves eth0 eth1
#     bond-mode active-backup
#     bond-miimon 100
#     bond-primary eth0
```

### トラブルシューティング

```bash
# ネットワークサービスの状態確認
sudo systemctl status networking

# ログの確認
sudo journalctl -u networking -f

# インターフェースの状態確認
ip link show
ethtool eth0  # インターフェースの詳細情報

# DNSの確認
cat /etc/resolv.conf
systemd-resolve --status  # systemd-resolvedを使用している場合

# ルーティングテーブルの確認
ip route show
route -n

# 接続性テスト
ping -c 4 8.8.8.8
traceroute google.com
```

### 注意事項

- NetworkManagerが有効な場合は、ifupdownと競合する可能性があります
- 設定変更前に必ずバックアップを取ってください
- リモート接続中の設定変更は接続が切れる可能性があるため注意が必要です
- VLANを使用する場合は、vlanパッケージのインストールが必要です: `sudo apt-get install vlan`

### NetworkManagerとの共存

```bash
# NetworkManagerで管理しないインターフェースを指定
sudo nano /etc/NetworkManager/NetworkManager.conf
# [keyfile]
# unmanaged-devices=interface-name:eth0,interface-name:eth1

# NetworkManagerの再起動
sudo systemctl restart NetworkManager
```