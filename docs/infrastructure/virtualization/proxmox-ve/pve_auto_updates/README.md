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

## 手動での設定手順

以下の手順でProxmox VEに自動セキュリティアップデートを設定できます：

1. 必要なパッケージのインストール：
```bash
# unattended-upgradesとapt-listchangesをインストール
apt update
apt install -y unattended-upgrades apt-listchanges
```

2. unattended-upgradesの有効化：
```bash
# debconfを使用して自動アップデートを有効化
echo "unattended-upgrades unattended-upgrades/enable_auto_updates boolean true" | debconf-set-selections
dpkg-reconfigure -plow unattended-upgrades
```

3. 設定ファイルの作成：
```bash
# 自動アップデートの設定を作成
cat > /etc/apt/apt.conf.d/50unattended-upgrades << 'EOF'
Unattended-Upgrade::Origins-Pattern {
        "origin=Debian,codename=${distro_codename}-security,label=Debian-Security";
};

Unattended-Upgrade::Automatic-Reboot "false";
EOF
```

4. 設定の確認と手動実行：
```bash
# ドライランで動作確認
unattended-upgrade --dry-run --debug

# 実際に実行（テスト用）
unattended-upgrade -d
```

5. 自動実行の確認：
```bash
# systemdタイマーの状態確認
systemctl status apt-daily.timer
systemctl status apt-daily-upgrade.timer

# ログの確認
tail -f /var/log/unattended-upgrades/unattended-upgrades.log
```

注意事項：
- 自動再起動は無効になっています（`Automatic-Reboot "false"`）
- Proxmox VEのパッケージは自動更新されません
- セキュリティアップデートのみが自動適用されます