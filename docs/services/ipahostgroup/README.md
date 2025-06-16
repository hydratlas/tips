# ipahostgroup

FreeIPA/IdMホストグループ管理ロール

FreeIPAサーバーにおいて、Automember機能を使えば不要のため現在未使用

## 概要

このロールは、FreeIPA/IdMのホストグループメンバーシップを管理します。指定されたホストを特定のホストグループに追加します。

## 要件

- FreeIPA/IdMサーバーへのアクセス
- 有効なKerberosチケットまたはIPA認証情報
- IPAモジュールの実行にroot権限が必要なため、プレイブックレベルで`become: true`の指定が必要

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

## 手動での設定手順

### 1. FreeIPA管理者として認証

```bash
# Kerberosチケットの取得
kinit admin

# または、パスワードを使用
echo "admin_password" | kinit admin
```

### 2. ホストグループの作成（存在しない場合）

```bash
# ホストグループの作成
ipa hostgroup-add webservers --desc="Web Servers"

# ホストグループの確認
ipa hostgroup-show webservers
```

### 3. ホストをホストグループに追加

```bash
# 単一ホストの追加
ipa hostgroup-add-member webservers --hosts=web01.examle.com

# 複数ホストの追加
ipa hostgroup-add-member webservers \
  --hosts=web01.examle.com,web02.examle.com,web03.examle.com

# または、個別に追加
ipa hostgroup-add-member webservers --hosts=web01.examle.com
ipa hostgroup-add-member webservers --hosts=web02.examle.com
ipa hostgroup-add-member webservers --hosts=web03.examle.com
```

### 4. ホストグループメンバーシップの確認

```bash
# ホストグループのメンバー一覧表示
ipa hostgroup-show webservers

# 特定のホストが所属するグループを確認
ipa host-show web01.examle.com --all | grep "Member of host-groups"
```

### 5. ホストグループからホストを削除（必要な場合）

```bash
# ホストの削除
ipa hostgroup-remove-member webservers --hosts=web01.examle.com
```

### 6. ホストグループの削除（必要な場合）

```bash
# ホストグループの削除
ipa hostgroup-del webservers
```

### FreeIPA Web UIでの設定

1. **FreeIPA Web UIにログイン**
   ```
   https://examle.com/ipa/ui/
   ```

2. **ホストグループの作成**
   - 「Identity」→「Host Groups」を選択
   - 「Add」ボタンをクリック
   - グループ名と説明を入力して「Add」

3. **ホストの追加**
   - 作成したホストグループをクリック
   - 「Host members」タブを選択
   - 「Add」ボタンをクリック
   - 追加したいホストを選択して「Add」

### Automemberを使用した自動割り当て

FreeIPAのAutomember機能を使用すると、ホスト名のパターンに基づいて自動的にホストグループに割り当てることができます：

```bash
# Automemberルールの作成
ipa automember-add --type=hostgroup webservers

# ホスト名パターンによる条件の追加（例：web*にマッチするホスト）
ipa automember-add-condition webservers --type=hostgroup \
  --inclusive-regex='^web.*\.int\.home\.arpa$' --key=fqdn

# Automemberルールの確認
ipa automember-show webservers --type=hostgroup

# 既存のホストにAutomemberルールを適用
ipa automember-rebuild --type=hostgroup
```

### 注意事項
- ホストグループへの追加には、FreeIPA管理者権限が必要です
- ホストは事前にFreeIPAに登録されている必要があります
- Automember機能を使用すると、このロールは不要になります
- ホストグループは、HBAC（Host-Based Access Control）ルールやsudoルールで使用できます