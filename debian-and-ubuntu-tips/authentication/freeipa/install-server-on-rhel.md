# FreeIPAサーバーをAlmaLinux 9に直接インストール
## ホスト名の設定およびFreeIPAサーバーのインストール
サーバーに割り当てられたIPアドレスが一つであることを前提にしている。二つ以上の場合は`host_name`変数を手動で設定すること。
```sh
host_name="$(hostname -s).$(awk '/^search / {print $2; exit}' "/etc/resolv.conf")" &&
sudo hostnamectl set-hostname "${host_name}" &&
sudo dnf install -y ipa-server
```

## FreeIPAサーバーのセットアップ
```sh
ds_password="$(cat /dev/urandom | tr -dc 'A-Za-z0-9!"#$%&'"'"'()*+,-./:;<=>?@[]\^_`{|}~' | head -c 12)" &&
admin_password="$(cat /dev/urandom | tr -dc 'A-Za-z0-9!"#$%&'"'"'()*+,-./:;<=>?@[]\^_`{|}~' | head -c 12)" &&
echo "Directory Manager user password: ${ds_password}" &&
echo "IPA admin user password: ${admin_password}" &&
sudo ipa-server-install \
  --unattended \
  --ds-password="${ds_password}" \
  --admin-password="${admin_password}" \
  --domain=home.arpa \
  --realm=HOME.ARPA \
  --no-ntp
```
- `--ds-password`オプションでは、FreeIPAのバックエンドで動作する389 Directory Server（LDAP）のDirectory Managerユーザーである「cn=Directory Manager」アカウントに対するパスワードを設定 
- `--admin-password`オプションでは、FreeIPAの管理者ユーザーである「admin」アカウントに対するパスワードを設定（Web UIやCLIからFreeIPAを操作する際に使用）

## 【デバッグ】ipa-server-installコマンドのヘルプの表示
```sh
ipa-server-install --help
```

## 【元に戻す】FreeIPAサーバーのアンインストール
```sh
sudo ipa-server-install --uninstall
```
