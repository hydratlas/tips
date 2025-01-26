# アカウントを使い分けるGitHubクライアントの設定方法
一つのシステムで複数のGitHubアカウントを扱うとき、SSHキーやGPGキーをアカウントごとに分けることでコンフリクトを防ぎ、安全にリポジトリーを操作できます。本ドキュメントでは、その手順を説明します。

## 対応環境
- Windows
    - Windows Terminal上のPowerShellコマンドライン
- Linux
    - Bash

## システム全体の設定
複数のアカウントを扱うにあたり、マシン全体に必要なパッケージをインストールし、環境設定を行います。

### パッケージのインストール
GitやGnuPG(GPG)が未インストールの場合は以下のコマンドで導入してください。

#### Windows
```powershell
winget install -e --id Microsoft.PowerShell
winget install -e --id Git.Git
winget install -e --id GnuPG.GnuPG
winget install -e --id GNU.Nano
$env:Path = [System.Environment]::GetEnvironmentVariable( `
  'Path', [System.EnvironmentVariableTarget]::Machine)
```

終わったら、ターミナルを再起動してください。または、PowerShellのバージョンが上がった場合には、次の手順を実行します。

1. Windows Terminalのタブの右側にある「▼」ボタンをクリックし、「設定」を選択します
1. 「スタートアップ」設定の中の「既定のプロファイル」をクリックして変更します
1. 一覧の中から、新しいPowerShell（例: `PowerShell`）を探して、選択します
1. 新しいタブを開きます

#### Linux（Debian系）
```sh
sudo apt-get install -y git gpg
```

### 【元に戻す】パッケージをアンインストール
インストールしたパッケージを削除する場合は、以下のコマンドを実行します。

#### Windows
```powershell
winget uninstall -e --id GnuPG.GnuPG
winget uninstall -e --id Git.Git
```

#### Linux
```sh
sudo apt-get purge -y git gpg
```

### 変数の準備
本手順では以下の変数を設定してから進める想定です。ドキュメント中で何度か繰り返し登場するため、最初に定義しておくとスムーズに作業できます。
- `$connectionName`: 任意のユーザー名
    - 実際のGitHubユーザー名とは異なっていても構いません
    - 例えば「personal」や「company」など、SSHキーペアを使い分ける中でどの関係先かが分かる名前にするとよいでしょう
    - このユーザー名の先頭3文字(firstThreeConnectionName)をSSHのホスト名設定で使用するため、3文字だけで一意に分かるようにしてください。たとえば「personal」なら先頭3文字は「per」となります
- `$githubUsername`: GitHubのユーザー名
- `$githubMail`: GitHubが用意したプライベートメールアドレス
    - GitHubから自動付与される「123456789+username@users.noreply.github.com」形式のメールアドレスです。実際のメールアドレスを公開しないために利用します
    - [GitHubの設定 > Emails](https://github.com/settings/emails)で確認できます

以下の例のように変数を設定します。

#### Windows
```powershell
$connectionName = "abcde"
$githubUsername = "username"
$githubMail = "123456789+username@users.noreply.github.com"
$firstThreeConnectionName = ${connectionName}.Substring( `
  0, [Math]::Min(${connectionName}.Length, 3))
$githubUserID = "${githubUsername} <${githubMail}>"
```

#### Linux
```sh
connection_name="abcde" &&
github_username="username" &&
github_mail="123456789+username@users.noreply.github.com" &&
first_three_connection_name="${github_username:0:3}" &&
github_userid="${github_username} <${github_mail}>"
```

### SSHキーペアとSSH設定ファイルの作成
ホスト名ごとに異なるSSHキーを使用できるよう、SSHの設定ファイル(~/.ssh/config)に接続設定を追加します。

実行後には、次の手順を実施します。

1. 最後に表示された公開鍵をコピーします
1. [GitHubの設定 > SSH and GPG keys > New SSH key](https://github.com/settings/keys)にペーストしてください
    - Titleにはデバイス名をつけると区別しやすいです

#### Windows
```powershell
$keyFile = "$HOME/.ssh/id_ed25519_${connectionName}"
ssh-keygen -t ed25519 -N '""' -C '""' -f "${keyFile}"
@"
Host github-${firstThreeConnectionName}
    HostName github.com
    IdentityFile ~/.ssh/id_ed25519_${connectionName}
    User git
"@ | Out-File -Append -FilePath "$HOME/.ssh/config" -Encoding utf8
cat "$keyFile.pub"
```

#### Linux
```sh
keyfile="$HOME/.ssh/id_ed25519_${connection_name}"
ssh-keygen -t ed25519 -N "" -C "" -f "${keyfile}" &&
tee "$HOME/.ssh/config" << EOS > /dev/null &&
Host github-${first_three_connection_name}
    HostName github.com
    IdentityFile ~/.ssh/id_ed25519_${connection_name}
    User git
EOS
cat "${keyfile}.pub"
```

### 【デバッグ】SSHキーペアの確認
SSHキーが正しく生成されているかを確認するときは、ファイルリストを確認します。

#### Windows
```powershell
ls -l "$HOME/.ssh"
```

#### Linux
```sh
ls -la "$HOME/.ssh"
```

### 【デバッグ】.ssh/configの確認
SSHの設定ファイルが正しい内容になっているか確認します。

#### Windows・Linux
```powershell
cat "$HOME/.ssh/config"
```

### 【デバッグ】.ssh/configの編集
SSHの設定ファイルを編集します。

#### Windows・Linux
```powershell
nano "$HOME/.ssh/config"
```

### 【元に戻す】生成したSSHキーペアの削除
不要になったSSHキーや誤って作成してしまったキーは以下のコマンドで削除できます。合わせて~/.ssh/configの該当行も削除してください。

#### Windows
```powershell
rm "${keyFile}.pub"
rm "${keyFile}"
```

#### Linux
```sh
rm "${keyfile}.pub" &&
rm "${keyfile}"
```

### GPGキーペアの作成
コミット署名やタグ署名などを行う場合は、GPGキーの作成とGitHubへの登録が必要です。

コミット署名やタグ署名を行うことを強く推奨します。署名付きのコミットやタグは、改ざんやなりすましを防ぎ、コードの信頼性を確保するために非常に重要です。

実行後には、次の手順を実施します。

1. 最後に表示された公開鍵をコピーします
1. [GitHubの設定 > SSH and GPG keys > New GPG key](https://github.com/settings/keys)にペーストしてください
    - Titleにはデバイス名をつけると区別しやすいです

#### Windows
```powershell
gpg --pinentry-mode loopback --passphrase '""' `
  --quick-gen-key "${githubUserID}" future-default - 0
gpg --armor --export "${githubUserID}"
```

#### Linux
```sh
gpg --pinentry-mode loopback --passphrase "" \
  --quick-gen-key "${github_userid}" future-default - 0 &&
gpg --armor --export "${github_userid}"
```

### 【デバッグ】GPGキー（秘密鍵）のリストの確認
生成したGPGキーが正しく登録されているかを確認するときは、秘密鍵のリストを確認します（公開鍵のみのリスト表示はできません）。

#### Windows・Linux
```powershell
gpg --list-secret-keys
```

### 【元に戻す】生成したGPGキーペアの削除
GPGキーが不要になった場合や再作成したい場合は、以下のコマンドを使用します。

#### Windows
```powershell
gpg --delete-secret-keys "${githubUserID}"
gpg --delete-keys "${githubUserID}"
```

#### Linux
```sh
gpg --delete-secret-keys "${github_userid}" &&
gpg --delete-keys "${github_userid}"
```

## プロジェクトごとの設定
ここからは各プロジェクトのディレクトリー単位で行う設定の手順です。複数のリポジトリーを扱う場合、それぞれのディレクトリーに対して同様の操作を行います。

### ディレクトリーの準備
1. 任意の場所にプロジェクト用のディレクトリーを作成します
2. ターミナルのカレントディレクトリーを、今作成したプロジェクト用ディレクトリーに移動します

### 変数の準備
さきほどと同様に、以下の変数を設定しておくと便利です。

#### Windows
```powershell
$connectionName = "abcde"
$githubUsername = "username"
$githubMail = "123456789+username@users.noreply.github.com"
$firstThreeConnectionName = ${connectionName}.Substring( `
  0, [Math]::Min(${connectionName}.Length, 3))
$githubUserID = "${githubUsername} <${githubMail}>"
```

#### Linux
```sh
connection_name="abcde" &&
github_username="username" &&
github_mail="123456789+username@users.noreply.github.com" &&
first_three_connection_name="${github_username:0:3}" &&
github_userid="${github_username} <${github_mail}>"
```

### 中身があるGitHubリポジトリーの場合
既存リポジトリーをクローンする例です。先頭3文字を使い、SSH設定ファイルで登録したホスト名を指定します。

#### Windows
```powershell
git clone "git@github-${firstThreeConnectionName}:<repository owner>/<repository name>.git" .
```

#### Linux
```sh
git clone "git@github-${first_three_connection_name}:<repository owner>/<repository name>".git .
```

### 空であるGitHubリポジトリーの場合
GitHub上に空のリポジトリーを作成してから、以下のコマンドで初期化とリモート登録を行います。

#### Windows
```powershell
git init --initial-branch=main
git remote add origin "git@github-${firstThreeConnectionName}:<repository owner>/<repository name>.git"
```

#### Linux
```sh
git init --initial-branch=main &&
git remote add origin "git@github-${first_three_connection_name}:<repository owner>/<repository name>.git"
```

### メールアドレスなどの設定
コミットで正しいユーザー名・メールアドレス・署名キーを使用するために、以下の設定を行います。プロジェクト単位で設定することで、他のプロジェクトに影響を与えずに済みます。

#### Windows
```powershell
git config user.name "${githubUsername}"
git config user.email "${githubMail}"
git config commit.gpgsign true
git config user.signingkey "${githubUserID}"
```

#### Linux
```sh
git config user.name "${github_username}" &&
git config user.email "${github_mail}" &&
git config commit.gpgsign true &&
git config user.signingkey "${github_userid}"
```

## まとめ
上記の流れで設定を行うことで、複数のGitHubアカウントを安全かつ混乱なく扱うことができます。
