# keepalived

VRRP高可用性設定ロール

## 概要

このロールは、Keepalivedを使用してVRRP（Virtual Router Redundancy Protocol）による高可用性を実現します。ジャンプホストなどの重要なサービスで仮想IPアドレスのフェイルオーバーを提供します。

## 要件

- Debian/RedHat系ディストリビューション
- rootまたはsudo権限
- ネットワークインターフェース設定済み

## ロール変数

### デフォルト変数

- `keepalived_config_file`: メイン設定ファイル（デフォルト: `/etc/keepalived/keepalived.conf`）
- `keepalived_config_dir`: 設定ディレクトリ（デフォルト: `/etc/keepalived/conf.d`）
- `keepalived_global_defs`: グローバル設定
- `keepalived_vrrp_instances`: VRRPインスタンス設定のリスト

### VRRPインスタンスパラメータ

- `name`: インスタンス名（必須）
- `interface`: インターフェース名（必須）
- `state`: MASTER/BACKUP（デフォルト: MASTER）
- `virtual_router_id`: 仮想ルーターID（必須）
- `priority`: 優先度（必須）
- `virtual_ipaddresses`: 仮想IPアドレスリスト（必須）
- `auth_type`/`auth_pass`: 認証設定（オプション）

## 使用例

### 基本設定

```yaml
- hosts: jamp_hosts
  become: true
  roles:
    - keepalived
```

### ホスト個別設定（host_vars）

```yaml
# jamp-01（MASTER）
keepalived_vrrp_instances:
  - name: "VI_1"
    interface: "eth0"
    state: "MASTER"
    virtual_router_id: 51
    priority: 100
    virtual_ipaddresses:
      - "10.120.20.51/16"

# jamp-02（BACKUP）
keepalived_vrrp_instances:
  - name: "VI_1"
    interface: "eth0"
    state: "BACKUP"
    virtual_router_id: 51
    priority: 90
    virtual_ipaddresses:
      - "10.120.20.51/16"
```

## 設定ファイル構造

- `/etc/keepalived/keepalived.conf` - メイン設定
- `/etc/keepalived/conf.d/00-global_defs.conf` - グローバル定義
- `/etc/keepalived/conf.d/<interface>.conf` - インターフェース別設定

## 動作確認

```bash
# ステータス確認
systemctl status keepalived

# 仮想IP確認
ip addr show dev eth0

# フェイルオーバーテスト
systemctl stop keepalived  # MASTERで実行
```