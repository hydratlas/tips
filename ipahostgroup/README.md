# ipahostgroup

FreeIPA/IdMホストグループ管理ロール

FreeIPAサーバーにおいて、Automember機能を使えば不要のため現在未使用

## 概要

このロールは、FreeIPA/IdMのホストグループメンバーシップを管理します。指定されたホストを特定のホストグループに追加します。

## 要件

- FreeIPA/IdMサーバーへのアクセス
- 有効なKerberosチケットまたはIPA認証情報

## ロール変数

- `ipahostgroup_name`: ホストグループ名
- `ipahostgroup_host`: グループに追加するホスト名

## 使用例

```yaml
- hosts: ipa_clients
  become: true
  vars:
    ipahostgroup_name: webservers
    ipahostgroup_host: "{{ inventory_hostname }}"
  roles:
    - ipahostgroup
```

## 設定内容

- FreeIPA APIを使用してホストグループメンバーシップを管理
- 指定されたホストをホストグループに追加