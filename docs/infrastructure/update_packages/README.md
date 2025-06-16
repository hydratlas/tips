# update_packages

システムパッケージを最新版に更新するAnsibleロール。

## 概要

このロールは、OSのパッケージマネージャーを使用してシステムパッケージを最新版に更新します。Debian系（apt）とRHEL系（dnf）の両方のディストリビューションに対応しています。

## 対応OS

- **Debian系**: Debian、Ubuntu
- **RHEL系**: RHEL、AlmaLinux、Rocky Linux、Fedora

## 設定内容

### Debian系の場合
- パッケージリストの更新（キャッシュ有効期間: 1時間）
- 全パッケージのアップグレード（`dist-upgrade`相当）

### RHEL系の場合
- 全パッケージを最新版に更新

## 使用例

```yaml
- hosts: all
  roles:
    - role: update_packages
```

特定のホストグループのみ更新する場合：

```yaml
- hosts: web_servers
  roles:
    - role: update_packages
```

## 注意事項

- カーネルやシステムパッケージの更新により、再起動が必要になる場合があります
- 重要なサービスを実行しているサーバーでは、メンテナンスウィンドウ内で実行することを推奨
- `dist-upgrade`（Debian系）は依存関係の解決のため、パッケージの削除を伴う場合があります

## トラブルシューティング

### 更新状況の確認

```bash
# Debian/Ubuntu
apt list --upgradable

# RHEL系
dnf check-update
```

### 再起動が必要かの確認

```bash
# Debian/Ubuntu
test -f /var/run/reboot-required && echo "再起動が必要です"

# RHEL系
needs-restarting -r
```

### パッケージのホールド（更新を防ぐ）

特定のパッケージを更新から除外したい場合：

```bash
# Debian/Ubuntu
apt-mark hold package-name

# RHEL系  
dnf versionlock add package-name
```

## 関連ロール

- システムの再起動が必要な場合は、別途再起動用のタスクまたはロールの使用を検討してください