# pve_auto_updates

このロールは、unattended-upgradesを使用してDebianシステムの自動セキュリティアップデートを設定します。

## 機能

1. unattended-upgradesとapt-listchangesパッケージをインストール
2. Debianセキュリティアップデートの自動適用を設定
3. 自動アップデートを有効化

## 変数

このロールに必要な変数はありません。

## 使用方法

```yaml
- hosts: proxmox_hosts
  roles:
    - pve_auto_updates
```

## 備考

このロールは、Debianセキュリティアップデートのみを自動的に適用します。Proxmox VEパッケージの自動アップデートは含まれていません。