# sssd_sudo_provider

SSSD sudoプロバイダー設定ロール

## 概要

このロールは、SSSDをFreeIPA/IdMのsudoプロバイダーとして設定します。これにより、FreeIPAサーバーで集中管理されたsudoルールを使用できるようになります。

## 要件

- SSSDがインストールされ、FreeIPA/IdMドメインに参加していること
- rootまたはsudo権限
- プレイブックレベルで`become: true`の指定が必要

## ロール変数

なし（このロールは固定の設定を適用します）

## 使用例

```yaml
- hosts: ipa_clients
  become: true
  roles:
    - sssd_sudo_provider
```

## 設定内容

- SSSDのsudoプロバイダー設定を追加
- FreeIPA/IdMサーバーからのsudoルール取得を有効化
- SSSDサービスの再起動
- 集中管理されたsudoポリシーの適用

## 手動での設定手順

### 設定

```bash
# SSSDパッケージのインストール（Debian系の場合）
sudo apt-get install -y sssd

# SSSDパッケージのインストール（RHEL系の場合）
sudo dnf install -y sssd

# SSSDサービスの停止
sudo systemctl stop sssd

# SSSD設定ファイルの編集
sudo vi /etc/sssd/sssd.conf

# [domain/YOUR_DOMAIN] セクションに以下を追加:
# sudo_provider = ipa

# 設定ファイルの権限設定（重要）
sudo chmod 600 /etc/sssd/sssd.conf
sudo chown root:root /etc/sssd/sssd.conf

# SELinuxコンテキストの設定（SELinuxが有効である場合）
sudo restorecon -R /etc/sssd/

# SSSDキャッシュのクリア
sudo rm -rf /var/lib/sss/db/*
sudo rm -rf /var/lib/sss/mc/*

# SSSDサービスの起動と有効化
sudo systemctl start sssd
sudo systemctl enable sssd

# 設定の確認
sudo sssctl config-check

# sudoルールのテスト
sudo -l
```

### トラブルシューティング

```bash
# SSSDの状態確認
sudo systemctl status sssd

# SSSDログの確認
sudo journalctl -u sssd -f

# デバッグレベルを上げる（/etc/sssd/sssd.conf）
# [domain/YOUR_DOMAIN]
# debug_level = 9

# sudoルールのキャッシュ確認
sudo sss_cache -E
sudo sss_cache -r

# FreeIPAサーバーとの接続確認
sudo ipa sudo-rule-find

# ローカルsudoersファイルとの競合確認
sudo visudo -c
```

### 注意事項

- SSSD設定ファイルの権限は必ず600に設定してください
- FreeIPAクライアントが正しく設定されている必要があります
- sudoルールはFreeIPAサーバー側で管理されます
- ローカルの/etc/sudoersファイルとFreeIPAのsudoルールは併用可能です