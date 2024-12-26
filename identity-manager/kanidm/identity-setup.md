# Kanidmのアイデンティティをセットアップ
Kanidm Clientから操作する。

## idm_adminアカウントにログイン
```sh
kanidm login --name idm_admin
```
idm_adminユーザーはID管理の管理者である。

## 「kishida230」ユーザーを作る
### ユーザーの作成
```sh
kanidm person create --name idm_admin kishida230 "F. Kishida"
```

### パスワード以外の設定
```sh
kanidm person update --name idm_admin kishida230 --legalname "Fumio Kishida" &&
kanidm person update --name idm_admin kishida230 --mail "kishida230@example.com" --mail "kishida230_2@example.com" &&
kanidm person posix set --name idm_admin kishida230 --shell /bin/bash &&
kanidm person posix set --name idm_admin kishida230 --gidnumber 2001 &&
kanidm person ssh add-publickey --name idm_admin kishida230 tag1 "ssh-ed25519 ...."
```

### パスワードの設定
SSHジャンプサーバーに使う分には不要。

まず、Google Authenticator（Google認証システム）などのOTPアプリをスマホに入れておく。
```sh
kanidm person credential update --name idm_admin kishida230
```
対話的に設定する。
- cred update (? for help) # : pw
- New password: パスワードを入力
- Confirm password: パスワードを入力
- cred update (? for help) # : totp
- TOTP Label: main
- QRコードが表示されるので、OTPアプリで読み込む。そうすると6桁の認証コードが表示される
- TOTP: 6桁の認証コードを入力
- cred update (? for help) # : commit
- Do you want to commit your changes? [y/n]: y

### posixパスワードの設定
```sh
kanidm person posix set-password --name idm_admin kishida230
```
対話的に設定する。
- New password: パスワードを入力
- Confirm password: パスワードを入力

### ユーザーの確認
```sh
kanidm person get --name idm_admin kishida230
```

### 全ユーザーの確認
```sh
kanidm person list --name idm_admin
```

### posix extensionsの確認
```sh
kanidm person posix show --name idm_admin kishida230
```

### ユーザーの変更
#### 名前の変更
```sh
kanidm person update --name idm_admin kishida230 --newname kishida230_2
```

#### 表示名の変更
```sh
kanidm person update --name idm_admin kishida230 --displayname "Fumio K."
```

### ユーザーの削除
```sh
kanidm person delete --name idm_admin kishida230
```

## 「ssh-jamp」グループを作る
### グループの作成
```sh
kanidm group create --name idm_admin ssh-jamp &&
kanidm group posix set --name idm_admin ssh-jamp --gidnumber 2003
```

### グループの確認
```sh
kanidm group get --name idm_admin ssh-jamp
```

### 全グループの確認
```sh
kanidm group list --name idm_admin
```

### グループのメンバーにユーザーを追加
```sh
kanidm group add-members --name idm_admin ssh-jamp kishida230
```

### グループのメンバーとなっているユーザーを表示
```sh
kanidm group list-members --name idm_admin ssh-jamp
```

### グループのメンバーからユーザーを削除
```sh
kanidm group remove-members --name idm_admin ssh-jamp kishida230
```

### グループの名前の変更
```sh
kanidm group rename --name idm_admin ssh-jamp ssh-jamp2
```

### グループの削除
```sh
kanidm group delete --name idm_admin ssh-jamp
```

## idm_adminアカウントからログアウト
```sh
kanidm logout --name idm_admin
```

## 【不要】「ssh-jamp-service」サービスアカウントの作成
### サービスアカウントの作成
```sh
kanidm service-account create --name idm_admin ssh-jamp-service "SSH Jamp Service" idm_admins
```

### トークンの生成
```sh
kanidm service-account api-token generate ssh-jamp-service "SSH Jamp Token" --name idm_admin
```

### トークンの状態の確認
```sh
kanidm service-account api-token status --name idm_admin ssh-jamp-service
```

### サービスアカウントの削除
```sh
kanidm service-account delete --name idm_admin ssh-jamp-service
```
