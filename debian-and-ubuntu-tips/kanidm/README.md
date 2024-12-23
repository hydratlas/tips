# Kanidm
## インストール・テスト
以下のコマンドを実行する前に、Podmanをインストールしておく。
```sh
sudo useradd --create-home --user-group kanidm &&
KANIDM_DATA="/opt/kanidm/data" &&
sudo mkdir -p "${KANIDM_DATA}" &&
sudo chown root:kanidm "${KANIDM_DATA}" "${KANIDM_DATA}/../" &&
sudo chmod ug+rwx,o=rx "${KANIDM_DATA}/../" &&
sudo chmod ug+rwx,o= "${KANIDM_DATA}" &&
sudo -u kanidm openssl genrsa -out "${KANIDM_DATA}/key.pem" 2048 &&
sudo -u kanidm openssl req -key "${KANIDM_DATA}/key.pem" -new -x509 -out "${KANIDM_DATA}/../ca.pem" -subj "/C=JP/CN=idm.home.arpa" &&
sudo -u kanidm openssl req -new -key "${KANIDM_DATA}/key.pem" -out "${KANIDM_DATA}/request.csr" -subj "/C=JP/CN=idm.home.arpa" &&
sudo -u kanidm openssl x509 -req -days 7300 -in "${KANIDM_DATA}/request.csr" -signkey "${KANIDM_DATA}/key.pem" -out "${KANIDM_DATA}/chain.pem" &&
sudo -u kanidm rm "${KANIDM_DATA}/request.csr" &&
sudo -u kanidm tee "${KANIDM_DATA}/server.toml" << EOS > /dev/null &&
bindaddress = "[::]:8443"
db_path = "/data/kanidm.db"
db_fs_type = "zfs"
tls_chain = "/data/chain.pem"
tls_key = "/data/key.pem"
domain = "idm.home.arpa"
origin = "https://idm.home.arpa/"

[online_backup]
path = "/data/kanidm/backups/"
schedule = "00 22 * * *"
EOS
sudo chown root:kanidm "${KANIDM_DATA}/server.toml" "${KANIDM_DATA}/key.pem" "${KANIDM_DATA}/chain.pem" &&
sudo chmod u=rw,g=r,o= "${KANIDM_DATA}/server.toml" "${KANIDM_DATA}/key.pem" "${KANIDM_DATA}/chain.pem" &&
sudo docker run --user "$(id -u kanidm):$(id -g kanidm)" --userns=keep-id --rm -it -v "${KANIDM_DATA}:/data" docker.io/kanidm/server:latest /sbin/kanidmd configtest
```

## サービス化
```sh
sudo tee "/etc/containers/systemd/kanidm-server.container" << EOS > /dev/null &&
[Container]
Image=docker.io/kanidm/server:latest
ContainerName=kanidm-server
AutoUpdate=registry
LogDriver=journald

PublishPort=8443:8443
Volume=${KANIDM_DATA}:/data:Z
Volume=/etc/localtime:/etc/localtime:ro
User=$(id -u kanidm)
Group=$(id -g kanidm)
UserNS=keep-id

[Service]
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOS
sudo systemctl daemon-reload &&
sudo systemctl start kanidm-server.service
```
- [Installing the Server - Kanidm Administration](https://kanidm.github.io/kanidm/stable/installing_the_server.html)


## 確認
```sh
sudo systemctl status --no-pager --full kanidm-server.service
systemctl cat --no-pager --full kanidm-server.service
sudo journalctl --no-pager --lines=30 -xeu kanidm-server.service
```

## 管理者アカウントの初期化
```sh
sudo docker exec -i -t kanidm-server kanidmd recover-account admin
sudo docker exec -i -t kanidm-server kanidmd recover-account idm_admin
```
ランダムなパスワードが生成されるので控えておく。

## 【デバッグ用】再起動
```sh
sudo systemctl restart kanidm-server.service
```

## 【デバッグ用】停止・削除
```sh
sudo systemctl stop kanidm-server.service &&
sudo rm /etc/containers/systemd/kanidm-server.service &&
sudo systemctl daemon-reload &&
sudo rm -dr /opt/kanidm
```
