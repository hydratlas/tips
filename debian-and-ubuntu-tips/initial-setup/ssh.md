# SSH周り
## SSHサーバーのインストールと設定（管理者）
```sh
sudo apt-get install --no-install-recommends -y openssh-server &&
sudo mkdir -p "/etc/ssh/sshd_config.d" &&
sudo tee "/etc/ssh/sshd_config.d/90-local.conf" << EOS > /dev/null
PasswordAuthentication no
PermitRootLogin no
EOS
```
パスワードによるログイン、rootユーザーでのログインを禁止する設定にしている。

## SSHサーバーの古い方式の禁止（管理者）
Includeで/etc/ssh/sshd_config.d/*.confが読み込まれているか確認。
```sh
grep -i Include /etc/ssh/sshd_config
```

読み込まれていないなら読み込むように追記。
```sh
sudo tee -a "/etc/ssh/sshd_config" <<< "Include /etc/ssh/sshd_config.d/*.conf" > /dev/null
```

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
