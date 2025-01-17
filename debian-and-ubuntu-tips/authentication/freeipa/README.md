# FreeIPA
## AlmaLinux 9に直接インストール
### ホスト名の設定およびFreeIPAサーバーのインストール
```sh
sudo hostnamectl set-hostname "idm-01.int.home.arpa" &&
sudo dnf install -y ipa-server
```

### FreeIPAサーバーのセットアップ
```sh
sudo ipa-server-install \
  --unattended \
  --ds-password=Secret123 \
  --admin-password=Secret123 \
  --domain=home.arpa \
  --realm=HOME.ARPA \
  --no-ntp
```

### 【デバッグ】ipa-server-installコマンドのヘルプの表示
```sh
ipa-server-install --help
```

### 【元に戻す】FreeIPAサーバーのアンインストール
```sh
sudo ipa-server-install --uninstall
```

## Podmanコンテナとしてインストール
### 注意
PodmanホストがRed Hat Enterprise Linux系ディストリビューションの場合には、ホストで`hostnamectl set-hostname`コマンドによってFQDN（完全修飾ドメイン名）を設定しておく必要がある。

### 事前設定
```sh
host_name="idm-01.int.home.arpa" &&
ip_address="10.120.21.21" &&
user_name="freeipa-server" &&
if hash apt-get 2>/dev/null; then
  sudo apt-get install -y podman
elif hash dnf 2>/dev/null; then
  sudo dnf install -y podman
fi &&
if ! id "${user_name}" &>/dev/null; then
  sudo useradd --system --no-create-home --user-group \
    --shell /usr/sbin/nologin "${user_name}"
fi &&
sudo install -o "root" -g "${user_name}" -m 775 -d "/var/local/lib/ipa-data"
```

### コンテナを起動
```sh
sudo podman run \
  --detach \
  --name freeipa-server \
  --hostname "${host_name}" \
  --sysctl net.ipv6.conf.all.disable_ipv6=0 \
  --volume "/var/local/lib/ipa-data:/data:Z" \
  --env IPA_SERVER_IP="${ip_address}" \
  --publish 8080:80 \
  --publish 443:443 \
  --publish 389:389 \
  --publish 636:636 \
  --publish 88:88/tcp --publish 88:88/udp \
  --publish 464:464/tcp --publish 464:464/udp \
  docker.io/freeipa/freeipa-server:almalinux-9 ipa-server-install \
  --unattended \
  --ds-password=Secret123 \
  --admin-password=Secret123 \
  --domain=home.arpa \
  --realm=HOME.ARPA \
  --no-ntp &&
sudo podman logs --follow freeipa-server
```
初回起動時には`ipaserver-install`コマンドによって初期設定が自動的に実行される。その判定は`/data`が空かどうかで行われる。

コンテナは`--detach`オプションによりバックグラウンドで起動させており、そのログを別途`podman logs`コマンドで表示させている。初期設定が完了したら「FreeIPA server configured.」と表示される。それを確認したら「Ctrl + C」キーでログの表示を終了させる。

### コンテナをいったん停止
```sh
sudo podman stop freeipa-server
```

### ipaserver-installコマンドの実行状況を確認
```sh
sudo podman logs --follow freeipa-server
```

### 【元に戻す】コンテナ、ディレクトリーおよびユーザーを削除
```sh
sudo podman rm freeipa-server &&
sudo rm -drf /var/local/lib/ipa-data &&
sudo userdel -r "${user_name}"
```

### 今後のため
```sh
--volume "/usr/local/share/ca-certificates/private-ca.crt:/etc/ipa/ca.crt:z,ro" \
--ca-cert-file=/root_ca.crt \
--dirsrv-cert-file=/ipa_server.crt \
--dirsrv-cert-file=/ipa_server.key \
--http-cert-file=/ipa_server.crt \
--http-cert-file=/ipa_server.key \
```
