# FreeIPAサーバーをAlmaLinux 9に直接インストール
## FreeIPAサーバーのインストール
### 事前設定
```sh
base_domain="home.arpa" &&
if hash wget 2>/dev/null; then
  eval "$(wget -q -O - "https://raw.githubusercontent.com/hydratlas/tips/refs/heads/main/scripts/freeipa")"
elif hash curl 2>/dev/null; then
  eval "$(curl "https://raw.githubusercontent.com/hydratlas/tips/refs/heads/main/scripts/freeipa")"
fi &&
chosen_domain &&
sudo hostnamectl set-hostname "${domain}" &&
ds_password="$(cat /dev/urandom | tr -dc 'A-Za-z0-9!"#$%&'"'"'()*+,-./:;<=>?@[]\^_`{|}~' | head -c 12)" &&
admin_password="$(cat /dev/urandom | tr -dc 'A-Za-z0-9!"#$%&'"'"'()*+,-./:;<=>?@[]\^_`{|}~' | head -c 12)" &&
echo "Directory Manager user password: ${ds_password}" &&
echo "IPA admin user password: ${admin_password}"
```

### インストール
```sh
sudo dnf install -y ipa-server &&
sudo ipa-server-install \
  --unattended \
  --ds-password="${ds_password}" \
  --admin-password="${admin_password}" \
  --domain="${base_domain,,}" \
  --realm="${base_domain^^}" \
  --no-ntp
```
- `--ds-password`オプションでは、FreeIPAのバックエンドで動作する389 Directory Server（LDAP）のDirectory Managerユーザーである「cn=Directory Manager」アカウントに対するパスワードを設定 
- `--admin-password`オプションでは、FreeIPAの管理者ユーザーである「admin」アカウントに対するパスワードを設定（Web UIやCLIからFreeIPAを操作する際に使用）

### 【デバッグ】ipa-server-installコマンドのヘルプの表示
```sh
ipa-server-install --help
```

### 【元に戻す】FreeIPAサーバーのアンインストール
```sh
sudo ipa-server-install --uninstall &&
sudo dnf remove -y ipa-server
```

## リバースプロキシをPodmanコンテナとして構築
### リバースプロキシをサービスとして追加・起動
```sh
sudo dnf install -y podman &&
if ! id "www-data" &>/dev/null; then
  sudo useradd --system --no-create-home --user-group \
    --shell /usr/sbin/nologin "www-data"
fi &&
sudo mkdir -p "/var/cache/nginx" &&
sudo install -m 775 -o "root" -g "www-data" -d \
  "/var/cache/nginx/freeipa-server-nginx" &&
sudo install -m 775 -o "root" -g "www-data" -d \
  "/var/run/freeipa-server-nginx" &&
sudo mkdir -p "/opt/freeipa-server-nginx" &&
sudo openssl req -x509 -nodes -days 7300 -newkey rsa:2048 \
  -keyout "/opt/freeipa-server-nginx/nginx.key" \
  -out "/opt/freeipa-server-nginx/nginx.crt" \
  -subj "/CN=${domain}" &&
sudo chown "root:www-data" \
  "/opt/freeipa-server-nginx/nginx.crt" "/opt/freeipa-server-nginx/nginx.key" &&
sudo chmod 644 "/opt/freeipa-server-nginx/nginx.crt" &&
sudo chmod 640 "/opt/freeipa-server-nginx/nginx.key" &&
sudo install \
  -m 644 -o "root" -g "www-data" \
  /dev/stdin "/opt/freeipa-server-nginx/nginx.conf" << EOS > /dev/null &&
worker_processes auto;

events {
  worker_connections 1024;
}

http {
  server {
    # ポートは10443でLISTENする
    listen 10443 ssl;

    # 証明書を設定
    ssl_certificate /etc/nginx/ssl/nginx.crt;
    ssl_certificate_key /etc/nginx/ssl/nginx.key;

    # どのHostヘッダが来ても受け取れるようにワイルドカード("_")指定
    server_name _;

    # Location以下でプロキシ設定
    location / {
      proxy_pass https://host.containers.internal/;

      # 内部サーバは "${domain}" でアクセスされるほうがよいため固定値を指定する
      proxy_set_header Host ${domain};
      proxy_set_header Referer "https://${domain}/ipa/ui/";

      # クライアントのIPアドレスを引き継ぎ
      proxy_set_header X-Forwarded-Proto https;
      proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;

      # FreeIPAサーバーの自己署名証明書を無条件で受け入れる設定 (検証を無効化)
      proxy_ssl_verify off;
      proxy_ssl_verify_depth 0;

      # FreeIPAのリダイレクトURLが "http://${domain}/..." のように返ってきたとき、
      # ブラウザ側で見えるURLを元のドメインに戻したいためproxy_redirectで書き換え
      proxy_redirect  http://${domain}/ https://\$host/;
      proxy_redirect https://${domain}/ https://\$host/;
    }
  }
}
EOS
sudo tee "/etc/containers/systemd/freeipa-server-nginx.container" << EOS > /dev/null &&
[Unit]
Description=Reverse Proxy for FreeIPA Server using nginx

[Container]
Image=docker.io/nginx:latest
ContainerName=freeipa-server-nginx
AutoUpdate=registry
LogDriver=journald
PublishPort=10443:10443
Volume=/opt/freeipa-server-nginx/nginx.conf:/etc/nginx/nginx.conf:ro,z
Volume=/opt/freeipa-server-nginx/nginx.crt:/etc/nginx/ssl/nginx.crt:ro,z
Volume=/opt/freeipa-server-nginx/nginx.key:/etc/nginx/ssl/nginx.key:ro,z
Volume=/var/cache/nginx/freeipa-server-nginx:/var/cache/nginx:Z
Volume=/var/run/freeipa-server-nginx:/var/run:Z
User=$(id -u www-data)
Group=$(id -g www-data)

[Service]
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOS
sudo systemctl daemon-reload &&
sudo systemctl start freeipa-server-nginx.service &&
sudo systemctl status --no-pager --full freeipa-server-nginx.service
```

### 【デバッグ】ログの表示
```sh
journalctl --no-pager --lines=20 --unit=freeipa-server-nginx.service
```

### 【元に戻す】リバースプロキシのサービスの停止・削除
```sh
sudo systemctl stop freeipa-server-nginx.service;
sudo rm /etc/containers/systemd/freeipa-server-nginx.container;
sudo systemctl daemon-reload
```
