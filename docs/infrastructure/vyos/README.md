# vyos

VyOSルーター設定ロール

## 概要

このロールは、VyOSルーターの設定を管理します。ベース設定とカスタム設定を組み合わせて、VyOSの設定を適用します。

## 要件

- VyOSルーター
- network_cli接続タイプ
- 適切な認証情報

## ロール変数

- `vyos_config_base`: ベース設定コマンドのリスト
- `vyos_config_custom`: カスタム設定コマンドのリスト

## 使用例

```yaml
- hosts: vyos_routers
  gather_facts: no
  vars:
    vyos_config_base:
      - set interfaces ethernet eth0 address dhcp
      - set service ssh port 22
    vyos_config_custom:
      - set system host-name router01
  roles:
    - vyos
```

## 設定内容

- ベース設定とカスタム設定のマージ
- VyOS設定モジュールを使用した設定の適用
- 設定の保存とコミット

## 手動での設定手順

### 設定の適用方法

VyOSでは、設定は設定モードで行い、commitで適用、saveで永続化します。

```bash
# 設定モードに入る
configure

# 設定コマンドを実行（例）
set interfaces ethernet eth0 address dhcp
set service ssh port 22

# 設定を適用
commit

# 設定を保存（永続化）
save

# 設定モードを終了
exit
```

### ベース設定の例

```bash
# VyOSにログイン後、設定モードに入る
configure

# インターフェース設定
set interfaces ethernet eth0 address dhcp
set interfaces ethernet eth1 address '192.168.1.1/24'

# SSH設定
set service ssh port 22
set service ssh disable-host-validation

# DNS設定
set system name-server '8.8.8.8'
set system name-server '8.8.4.4'

# NTP設定
set system ntp server '0.pool.ntp.org'
set system ntp server '1.pool.ntp.org'

# 設定を適用して保存
commit
save
exit
```

### DHCP固定IPマッピング設定

```bash
configure

# DHCPサーバー設定
set service dhcp-server shared-network-name LAN subnet 192.168.1.0/24 range 0 start '192.168.1.100'
set service dhcp-server shared-network-name LAN subnet 192.168.1.0/24 range 0 stop '192.168.1.200'

# 固定IPマッピング
set service dhcp-server shared-network-name LAN subnet 192.168.1.0/24 static-mapping host1 ip-address '192.168.1.10'
set service dhcp-server shared-network-name LAN subnet 192.168.1.0/24 static-mapping host1 mac-address '00:11:22:33:44:55'

commit
save
exit
```

### カスタム設定の例

```bash
configure

# ホスト名設定
set system host-name 'router01'

# タイムゾーン設定
set system time-zone 'Asia/Tokyo'

# ファイアウォール設定
set firewall name OUTSIDE-IN default-action 'drop'
set firewall name OUTSIDE-IN rule 10 action 'accept'
set firewall name OUTSIDE-IN rule 10 state established 'enable'
set firewall name OUTSIDE-IN rule 10 state related 'enable'

# インターフェースにファイアウォールを適用
set interfaces ethernet eth0 firewall in name 'OUTSIDE-IN'

commit
save
exit
```

### 複数の設定を一度に適用

```bash
# スクリプトファイルを作成
cat > /tmp/vyos-config.txt << 'EOF'
set interfaces ethernet eth0 address dhcp
set interfaces ethernet eth1 address '192.168.1.1/24'
set service ssh port 22
set system host-name 'router01'
set system time-zone 'Asia/Tokyo'
EOF

# 設定を一括適用
configure
load /tmp/vyos-config.txt
commit
save
exit
```

### 設定のバックアップとリストア

```bash
# 現在の設定をファイルに保存
show configuration commands > /config/backup-config.txt

# 設定をリストア
configure
load /config/backup-config.txt
commit
save
exit
```

### 設定の確認

```bash
# 実行中の設定を表示
show configuration

# 設定コマンド形式で表示
show configuration commands

# 特定の設定セクションのみ表示
show configuration commands | grep interface

# 設定の差分を確認（commit前）
configure
set interfaces ethernet eth2 address '192.168.2.1/24'
compare
exit discard  # 変更を破棄
```

### Ansibleロールと同等の処理

このロールは以下の処理を実行します：

1. **設定の結合**
   ```bash
   # ベース設定 + DHCPマッピング設定 + カスタム設定を結合
   # 手動では各設定を順番に適用
   ```

2. **設定の適用**
   ```bash
   configure
   # 各設定コマンドを実行
   commit
   save
   exit
   ```

### 注意事項
- VyOSの設定は設定モードで行う必要があります
- commitしないと設定は適用されません
- saveしないと再起動時に設定が失われます
- 設定エラーがある場合、commitは失敗します
