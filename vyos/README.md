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