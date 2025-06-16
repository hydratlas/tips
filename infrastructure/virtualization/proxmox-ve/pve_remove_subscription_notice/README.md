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

このロールは、datacenter.cfgファイルに設定を追加する前にバックアップを作成します。この方法は、Proxmoxのアップデート時にも設定が保持される、より安定した方法です。