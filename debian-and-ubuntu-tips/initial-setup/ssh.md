# SSH周り
## SSHサーバーのインストール（管理者）
### インストール
```sh
sudo apt-get install --no-install-recommends -y openssh-server
```

### sshd_config.dディレクトリーの作成・有効化
```sh
sudo mkdir -p "/etc/ssh/sshd_config.d" &&
PERL_SCRIPT="s@^#Include /etc/ssh/sshd_config\.d/\*\.conf\$@Include /etc/ssh/sshd_config.d/*.conf@g" &&
sudo perl -p -i -e "$PERL_SCRIPT" "/etc/ssh/sshd_config" &&
REGEX='^Include /etc/ssh/sshd_config\.d/\*\.conf$' &&
if ! grep -qP "$REGEX" "/etc/ssh/sshd_config";then
  echo -e "Include /etc/ssh/sshd_config.d/*.conf" | sudo tee -a "/etc/ssh/sshd_config" > /dev/null
fi
```

### パスワードによるログインおよびrootユーザーでのログインの禁止
```sh
sudo tee "/etc/ssh/sshd_config.d/90-local.conf" << EOS > /dev/null
PasswordAuthentication no
PermitRootLogin no
EOS
```

## SSHサーバーの設定変更（管理者）
### 共通
`grep -i Include /etc/ssh/sshd_config`コマンドで/etc/ssh/sshd_config.d/*.confが読み込まれているか確認し、読み込まれていなかったら読み込まれるようにする。

### ポートの追加・変更
はじめに、`sudo nano /lib/systemd/system/ssh.socket`コマンドでファイルを編集する。以下のように`[Socket]`セクションに`ListenStream`の無指定（リセット用）、使いたいポート（複数行可）を書く。
```
[Socket]
ListenStream=
ListenStream=22
ListenStream=10022
```

次に以下のコマンドを実行する。
```sh
sudo tee -a "/etc/ssh/sshd_config.d/92-ports.conf" << EOS > /dev/null &&
Port 22
Port 10022
EOS
sudo systemctl daemon-reload &&
sudo systemctl restart ssh.socket &&
sudo systemctl restart ssh.service &&
ss -nlt
```
StateがLISTENであるポートが意図したとおりなら完了。`ssh`コマンドに`-p <port>`オプションを追加して接続する。

### SSHサーバーの古い方式の禁止
```sh
sudo tee "/etc/ssh/sshd_config.d/91-local.conf" << EOS > /dev/null
Ciphers -*-cbc
KexAlgorithms -*-sha1
PubkeyAcceptedKeyTypes -ssh-rsa*,ssh-dss*
EOS

sudo sshd -T | grep -i -e PasswordAuthentication -e PermitRootLogin

sudo sshd -T | grep -i -e Ciphers -e MACs -e PubkeyAcceptedKeyTypes -e PubkeyAcceptedAlgorithms -e KexAlgorithms
```
古いタイプの方式を禁止する設定。PubkeyAcceptedKeyTypesはOpenSSH 8.5からPubkeyAcceptedAlgorithmsに名前が変わっている。Ubuntu 20.04は8.2、22.04は8.9。OpenSSH 8.5以降でもPubkeyAcceptedKeyTypesによる禁止設定は効果がある。

## ユーザーにauthorized_keysを作成または追記（各ユーザー）
```sh
USER_NAME=<username> &&
KEYS=$(cat << EOS
ssh-ed25519 xxxxx
ssh-ed25519 xxxxx
EOS
) &&
USER_HOME="$(grep "$USER_NAME" /etc/passwd | cut -d: -f6)" &&
sudo -u "$USER_NAME" mkdir -p "$USER_HOME/.ssh" &&
sudo -u "$USER_NAME" tee -a "$USER_HOME/.ssh/authorized_keys" <<< "$KEYS" > /dev/null &&
sudo chmod u=rw,g=,o= "$USER_HOME/.ssh/authorized_keys"
```

## SSHキーを生成（各ユーザー）
```sh
mkdir -p "$HOME/.ssh" &&
ssh-keygen -t rsa   -b 4096 -N '' -C '' -f "$HOME/.ssh/id_rsa" &&
ssh-keygen -t ecdsa  -b 521 -N '' -C '' -f "$HOME/.ssh/id_ecdsa" &&
ssh-keygen -t ed25519       -N '' -C '' -f "$HOME/.ssh/id_ed25519"
```
