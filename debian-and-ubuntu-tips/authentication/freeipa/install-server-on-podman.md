# FreeIPAサーバーをPodmanコンテナとしてインストール
## 事前設定
```sh
ds_password="$(cat /dev/urandom | tr -dc 'A-Za-z0-9!"#$%&'"'"'()*+,-./:;<=>?@[]\^_`{|}~' | head -c 12)" &&
admin_password="$(cat /dev/urandom | tr -dc 'A-Za-z0-9!"#$%&'"'"'()*+,-./:;<=>?@[]\^_`{|}~' | head -c 12)" &&
base_domain="home.arpa" &&
user_name="freeipa-server" &&
echo "Directory Manager user password: ${ds_password}" &&
echo "IPA admin user password: ${admin_password}" &&
if hash apt-get 2>/dev/null; then
  sudo apt-get install -y podman
elif hash dnf 2>/dev/null; then
  sudo dnf install -y podman
fi &&
eval "$(wget -q -O - "https://raw.githubusercontent.com/hydratlas/tips/refs/heads/main/scripts/freeipa")" &&
chosen_domain &&
chosen_nameserver &&
chosen_ip_address &&
if ! id "${user_name}" &>/dev/null; then
  sudo useradd --system --no-create-home --user-group \
    --shell /usr/sbin/nologin "${user_name}"
fi &&
sudo install -o "root" -g "${user_name}" -m 775 -d "/var/local/lib/ipa-data"
```

## ネットワークの作成
```sh
sudo mkdir -p /etc/containers/systemd &&
sudo tee /etc/containers/systemd/freeipa.network << EOS > /dev/null
[Unit]
Description=FreeIPA Container Network

[Network]
Label=app=freeipa
EOS
```

## コンテナを起動
コンテナは`--detach`オプションによりバックグラウンドで起動させており、そのログを別途`podman logs`コマンドで表示させている。初期設定が完了したら「FreeIPA server configured.」と表示される。それを確認したら「Ctrl + C」キーでログの表示を終了させる。

### マスター
```sh
# --read-only
# -v 
sudo podman run \
  --detach \
  --name=freeipa-server \
  --hostname="${domain}" \
  --dns="${nameserver}"
  --sysctl=net.ipv6.conf.all.disable_ipv6=0 \
  --volume="/var/local/lib/ipa-data:/data:Z" \
  --volume="/sys/fs/cgroup:/sys/fs/cgroup:z,ro" \
  --env IPA_SERVER_IP="${ip_address}" \
  --publish 80:80 \
  --publish 443:443 \
  --publish 389:389 \
  --publish 636:636 \
  --publish 88:88/tcp --publish 88:88/udp \
  --publish 464:464/tcp --publish 464:464/udp \
  docker.io/freeipa/freeipa-server:almalinux-9 ipa-server-install \
  --unattended \
  --read-only \
  --ds-password="${ds_password}" \
  --admin-password="${admin_password}" \
  --domain="${base_domain,,}" \
  --realm="${base_domain^^}" \
  --setup-dns \
  --no-ntp &&
sudo podman logs --follow freeipa-server
```

### レプリカ
```sh
sudo podman run \
  --detach \
  --name=freeipa-server \
  --hostname="${domain}" \
  --dns="${nameserver}"
  --sysctl=net.ipv6.conf.all.disable_ipv6=0 \
  --volume="/var/local/lib/ipa-data:/data:Z" \
  --env IPA_SERVER_IP="${ip_address}" \
  --publish 80:80 \
  --publish 443:443 \
  --publish 389:389 \
  --publish 636:636 \
  --publish 88:88/tcp --publish 88:88/udp \
  --publish 464:464/tcp --publish 464:464/udp \
  docker.io/freeipa/freeipa-server:almalinux-9 ipa-replica-install \
  --unattended \
  --setup-dns \
  --no-ntp &&
sudo podman logs --follow freeipa-server
```

## コンテナをいったん停止
```sh
sudo podman stop freeipa-server
```

## 【元に戻す】コンテナ、ディレクトリーおよびユーザーを削除
```sh
sudo podman rm freeipa-server &&
sudo rm -drf /var/local/lib/ipa-data &&
sudo userdel -r "${user_name}"
```

## サービス化
```sh
sudo tee "/etc/containers/systemd/freeipa-server.container" << EOS > /dev/null &&
[Unit]
Description=FreeIPA Server Container
Wants=network-online.target
After=network-online.target

[Container]
Image=docker.io/freeipa/freeipa-server:almalinux-9
ContainerName=freeipa-server
Network=freeipa.network
DNS=${nameserver}
Sysctl=net.ipv6.conf.all.disable_ipv6=0
Volume=/var/local/lib/ipa-data:/data:Z
PublishPort=80:80
PublishPort=443:443
PublishPort=389:389
PublishPort=636:636
PublishPort=88:88/tcp
PublishPort=88:88/udp
PublishPort=464:464/tcp
PublishPort=464:464/udp

[Service]
Restart=on-failure
Environment=IPA_SERVER_IP=${ip_address}
Environment=FORWARDER=${nameserver}

[Install]
WantedBy=multi-user.target
EOS
sudo systemctl daemon-reload &&
sudo systemctl start freeipa-server.service &&
sudo systemctl status --no-pager --full freeipa-server.service
```

## 【元に戻す】サービスの停止・削除
```sh
sudo systemctl stop freeipa-server.service &&
sudo rm /etc/containers/systemd/freeipa-server.container &&
sudo systemctl daemon-reload
```

## リバースプロキシを構築
```sh
host_name="$(hostname -s).$(awk '/^search / {print $2; exit}' "/etc/resolv.conf")" &&
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
  -subj "/CN=${host_name}" &&
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
    # ポートは8443でLISTENする
    listen 8443 ssl;

    # 証明書を設定
    ssl_certificate /etc/nginx/ssl/nginx.crt;
    ssl_certificate_key /etc/nginx/ssl/nginx.key;

    # どのHostヘッダが来ても受け取れるようにワイルドカード("_")指定
    server_name _;

    # Location以下でプロキシ設定
    location / {
      proxy_pass https://freeipa-server/;

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
Wants=freeipa-server.service
After=freeipa-server.service

[Container]
Image=docker.io/nginx:latest
ContainerName=freeipa-server-nginx
Network=freeipa.network
AutoUpdate=registry
LogDriver=journald
PublishPort=8443:8443
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

## 【元に戻す】リバースプロキシのサービスの停止・削除
```sh
sudo systemctl stop freeipa-server-nginx.service &&
sudo rm /etc/containers/systemd/freeipa-server-nginx.container &&
sudo systemctl daemon-reload
```
