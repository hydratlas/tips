# Kanidm Serverのセットアップ
## 前提
Podmanをインストールしておく必要がある。

## ユーザー・ディレクトリー・鍵の準備
```sh
CA_DIR="/opt/ca" &&
SERVER_DIR="/opt/kanidm" &&
SERVER_DATA_DIR="/opt/kanidm/data" &&
SERVER_USER="kanidm" &&
CA_FILENAME="ca" &&
SERVER_FILENAME="idm-server" &&
CA_FQDN="ca.home.arpa" &&
SERVER_FQDN="idm.int.home.arpa" &&
CA_SUBJ="/C=JP/CN=${CA_FQDN}" &&
SERVER_SUBJ="/C=JP/CN=${SERVER_FQDN}" &&
cd ~/ &&
if ! id "${SERVER_USER}" &>/dev/null; then
    sudo useradd --create-home --user-group "${SERVER_USER}"
fi &&
if [ ! -e "${CA_DIR}/${CA_FILENAME}.crt" ]; then
  openssl genpkey -algorithm RSA -pkeyopt rsa_keygen_bits:4096 -out "${CA_FILENAME}.key" &&
  openssl req -x509 -new -nodes -key "${CA_FILENAME}.key" -sha256 -days 7300 -out "${CA_FILENAME}.crt" -subj "${CA_SUBJ}" &&
  sudo install -o root -g root -m 755 -d "${CA_DIR}" &&
  sudo install -o root -g root -m 600 -t "${CA_DIR}" "${CA_FILENAME}.key" &&
  rm "${CA_FILENAME}.key" &&
  sudo install -o root -g root -m 644 -t "${CA_DIR}" "${CA_FILENAME}.crt" &&
  rm "${CA_FILENAME}.crt" &&
fi &&
if [ ! -e "${SERVER_DIR}/${SERVER_FILENAME}.crt" ]; then
  openssl genpkey -algorithm RSA -pkeyopt rsa_keygen_bits:2048 -out "${SERVER_FILENAME}.key" &&
  openssl req -new -key "${SERVER_FILENAME}.key" -out "${SERVER_FILENAME}.csr" -subj "${SERVER_SUBJ}" &&
  tee "${SERVER_FILENAME}.cnf" << EOS > /dev/null &&
[ req ]
x509_extensions = v3_ca

[ v3_ca ]
basicConstraints = CA:false
keyUsage = nonRepudiation, digitalSignature, keyEncipherment
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid,issuer
subjectAltName = @alt_names

[alt_names]
DNS.1 = ${SERVER_FQDN}
EOS
  sudo openssl x509 -req -in "${SERVER_FILENAME}.csr" -CA "${CA_DIR}/${CA_FILENAME}.crt" -CAkey "${CA_DIR}/${CA_FILENAME}.key" -CAcreateserial -out "${SERVER_FILENAME}.crt" -days 7300 -sha256 -extensions v3_ca -extfile "${SERVER_FILENAME}.cnf" &&
  sudo chown "${USER}:${USER}" "${SERVER_FILENAME}.crt" &&
  rm "${SERVER_FILENAME}.cnf" &&
  sudo install -o root -g "${SERVER_USER}" -m 775 -d "${SERVER_DIR}" &&
  sudo install -o root -g "${SERVER_USER}" -m 640 -t "${SERVER_DIR}" "${SERVER_FILENAME}.key" &&
  rm "${SERVER_FILENAME}.key" &&
  sudo install -o root -g root -m 644 -t "${SERVER_DIR}" "${SERVER_FILENAME}.csr" &&
  rm "${SERVER_FILENAME}.csr" &&
  sudo install -o root -g root -m 644 -t "${SERVER_DIR}" "${SERVER_FILENAME}.crt" &&
  rm "${SERVER_FILENAME}.crt"
fi &&
sudo install -o root -g "${SERVER_USER}" -m 770 -d "${SERVER_DATA_DIR}" &&
sudo install -o root -g "${SERVER_USER}" -m 640 -t "${SERVER_DATA_DIR}" "${SERVER_DIR}/${SERVER_FILENAME}.key" &&
sudo install -o root -g "${SERVER_USER}" -m 644 -t "${SERVER_DATA_DIR}" "${SERVER_DIR}/${SERVER_FILENAME}.crt"
```

## インストール・テスト
```sh
sudo tee "${SERVER_DATA_DIR}/server.toml" << EOS > /dev/null &&
bindaddress = "[::]:8443"
db_path = "/data/kanidm.db"
db_fs_type = "zfs"
tls_chain = "/data/${SERVER_FILENAME}.crt"
tls_key = "/data/${SERVER_FILENAME}.key"
domain = "${SERVER_FQDN}"
origin = "https://${SERVER_FQDN}/"

[online_backup]
path = "/data/kanidm/backups/"
schedule = "00 22 * * *"
EOS
sudo chown root:kanidm "${SERVER_DATA_DIR}/server.toml" &&
sudo chmod 640 "${SERVER_DATA_DIR}/server.toml" &&
sudo docker run --user "$(id -u kanidm):$(id -g kanidm)" --userns=keep-id --rm -it -v "${SERVER_DIR}:/data" docker.io/kanidm/server:latest /sbin/kanidmd configtest
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
Volume=${SERVER_DIR}:/data:Z
Volume=/etc/localtime:/etc/localtime:ro,z
User=$(id -u kanidm)
Group=$(id -g kanidm)
UserNS=keep-id

[Service]
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOS
sudo systemctl daemon-reload &&
sudo systemctl start kanidm-server.service &&
sudo systemctl status --no-pager --full kanidm-server.service
```
- [Installing the Server - Kanidm Administration](https://kanidm.github.io/kanidm/stable/installing_the_server.html)


## 確認
```sh
sudo systemctl status --no-pager --full kanidm-server.service
systemctl cat --no-pager --full kanidm-server.service
sudo journalctl --no-pager --lines=30 -xeu kanidm-server.service
```

## サーバー証明書の確認
```sh
openssl x509 -noout -text -in "${SERVER_DIR}/${SERVER_FILENAME}.crt"
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
sudo rm /etc/containers/systemd/kanidm-server.container &&
sudo systemctl daemon-reload &&
sudo rm -dr /opt/kanidm
```
