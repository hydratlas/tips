# pve_remove_subscription_notice

このロールは、有効なサブスクリプションがない場合にProxmox VEのWebインターフェースに表示されるサブスクリプション広告ポップアップを削除します。

## 機能

1. /etc/pve/datacenter.cfgにサブスクリプションチェックの無効化設定を追加
2. 変更を適用するためにpveproxyサービスを再起動

## 変数

このロールに必要な変数はありません。

## 使用方法

```yaml
- hosts: proxmox_hosts
  roles:
    - pve_remove_subscription_notice
```

## 備考

このロールは、JavaScriptファイルを修正してサブスクリプション通知を無効化します。Proxmoxのアップデート時には再度適用が必要になる場合があります。

## 手動での設定手順

以下の手順でProxmox VEのサブスクリプション通知を削除できます：

### 方法1: JavaScriptファイルの修正（現在のロールの方法）

1. JavaScriptファイルのバックアップ：
```bash
# proxmoxlib.jsファイルをバックアップ
cp /usr/share/javascript/proxmox-widget-toolkit/proxmoxlib.js \
   /usr/share/javascript/proxmox-widget-toolkit/proxmoxlib.js.bak
```

2. サブスクリプション通知の無効化：
```bash
# sedを使用してサブスクリプション通知を無効化
sed -i.bak "s/Ext.Msg.show({/void({ \/\/Ext.Msg.show({/g" \
    /usr/share/javascript/proxmox-widget-toolkit/proxmoxlib.js
```

3. pveproxyサービスの再起動：
```bash
# 変更を適用するためにpveproxyを再起動
systemctl restart pveproxy
```

### 方法2: 代替方法（datacenter.cfgの設定）

```bash
# datacenter.cfgにサブスクリプションチェックの無効化設定を追加
echo "no-subscription-warning: 1" >> /etc/pve/datacenter.cfg

# pveproxyサービスの再起動
systemctl restart pveproxy
```

### 変更の確認

1. ブラウザのキャッシュをクリア
2. Proxmox VE Web UIに再度ログイン
3. サブスクリプション通知が表示されないことを確認

注意事項：
- JavaScriptファイルの修正は、Proxmox VEのアップデート時に上書きされる可能性があります
- アップデート後は再度手順を実行する必要がある場合があります
- バックアップファイルは必ず保存しておいてください