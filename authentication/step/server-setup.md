# step-ca（サーバー）
## 準備
Podmanをインストールしておく。

## ルートCA証明書の作成
### ユーザーおよびディレクトリーの作成
```sh
if ! id "step-ca" &>/dev/null; then
  sudo useradd --system --no-create-home --user-group --shell /usr/sbin/nologin "step-ca"
fi &&
sudo install -o "root" -g "step-ca" -m 775 -d "/opt/ca/root" "/opt/ca/federated-roots"
```

### 秘密鍵の作成
```sh
OUT_FILEPATH="/opt/ca/root/root_ca_key" &&
sudo -u "step-ca" openssl genpkey -algorithm ED25519 -out "${OUT_FILEPATH}" &&
sudo chmod 640 "${OUT_FILEPATH}" &&
sudo chown "root:step-ca" "${OUT_FILEPATH}"
```

### 設定ファイルの作成
```sh
sudo install -m 644 -o "root" -g "step-ca" /dev/stdin "/opt/ca/root/openssl.cnf" << EOS > /dev/null
[ req ]
default_md              = sha512
prompt                  = no
x509_extensions         = v3_ca

[ v3_ca ]
subjectKeyIdentifier    = hash
authorityKeyIdentifier  = keyid:always, issuer
basicConstraints        = critical, CA:true
keyUsage                = critical, keyCertSign, cRLSign
EOS
```

### 証明書の作成
```sh
OUT_FILEPATH="/opt/ca/root/root_ca.crt" &&
sudo -u "step-ca" openssl req -x509 -new \
  -key "/opt/ca/root/root_ca_key" -nodes \
  -out "${OUT_FILEPATH}" \
  -subj "/O=CN=Private $(hostname)/CN=Private $(hostname) Root CA" \
  -days 7300 \
  -config "/opt/ca/root/openssl.cnf" &&
sudo chmod 644 "${OUT_FILEPATH}" &&
sudo chown "root:step-ca" "${OUT_FILEPATH}"
```

### 【オプション】ほかのプライベート認証局サーバーのルート証明書の追加
#### ファイルの作成
```sh
OUT_FILEPATH="/opt/ca/federated-roots/peer_root_ca.crt" &&
sudo -u "step-ca" touch "${OUT_FILEPATH}" &&
sudo chmod 644 "${OUT_FILEPATH}" &&
sudo chown "root:step-ca" "${OUT_FILEPATH}"
```

#### ファイルの編集
```sh
sudo nano "${OUT_FILEPATH}"
```
ほかのサーバーで`cat /opt/ca/root/root_ca.crt`コマンドを実行し表示された内容を入力する。

### 【デバッグ】確認
#### 秘密鍵の表示
```sh
sudo -u "step-ca" cat "/opt/ca/root/root_ca_key"
```

#### 証明書の概要
```sh
openssl x509 -text -noout -in "/usr/local/share/ca-certificates/private-ca.crt"
openssl x509 -text -noout -in "/usr/local/share/ca-certificates/peer-private-ca.crt"
```

#### 証明書の表示
```sh
cat "/usr/local/share/ca-certificates/private-ca.crt"
cat "/usr/local/share/ca-certificates/peer-private-ca.crt"
```

### 【元に戻す】削除
```sh
sudo rm -dr "/opt/ca" &&
sudo userdel "step-ca"
```

## step-caのインストール
### 変数の設定、ならびにユーザーおよびディレクトリーの作成
```sh
STEPCA_CONTAINER_DATAPATH="/home/step" &&
PROVISIONER_PASSWORD_FILENAME="provisioner-password" &&
PASSWORD_FILENAME="password" &&
CA_CONTAINER_DATAPATH="/home/ca" &&
sudo install -o "root" -g "step-ca" -m 775 -d "/opt/step-ca" &&
sudo install -o "step-ca" -g "step-ca" -m 700 -d "/opt/step-ca/secrets"
```

### step-caのインストール
```sh
OUT_FILEPATH="/opt/step-ca/secrets/${PROVISIONER_PASSWORD_FILENAME}" &&
sudo -u "step-ca" openssl rand -base64 -out "${OUT_FILEPATH}" 32 &&
sudo chmod 600 "${OUT_FILEPATH}" &&
sudo chown "step-ca:step-ca" "${OUT_FILEPATH}" &&
OUT_FILEPATH="/opt/step-ca/secrets/${PASSWORD_FILENAME}" &&
sudo -u "step-ca" openssl rand -base64 -out "${OUT_FILEPATH}" 32 &&
sudo chmod 600 "${OUT_FILEPATH}" &&
sudo chown "step-ca:step-ca" "${OUT_FILEPATH}" &&
sudo podman run \
  --user "$(id -u step-ca):$(id -g step-ca)" \
  --interactive --tty \
  --userns=keep-id \
  --volume "/opt/step-ca:${STEPCA_CONTAINER_DATAPATH}:Z" \
  --volume "/opt/ca:${CA_CONTAINER_DATAPATH}:ro,z" \
  docker.io/smallstep/step-ca \
    step ca init \
    --deployment-type="standalone" \
    --name="Private $(hostname)" \
    --dns="$(hostname -A | tr ' ' '\n' | grep -F '.' | paste -sd ',' -),localhost" \
    --address=":8443" \
    --root="${CA_CONTAINER_DATAPATH}/root/root_ca.crt" \
    --key="${CA_CONTAINER_DATAPATH}/root/root_ca_key" \
    --password-file="${STEPCA_CONTAINER_DATAPATH}/secrets/${PASSWORD_FILENAME}" \
    --provisioner="admin" \
    --provisioner-password-file="${STEPCA_CONTAINER_DATAPATH}/secrets/${PROVISIONER_PASSWORD_FILENAME}" \
    --acme \
    --ssh \
    --remote-management
```

### 【オプション】ほかのプライベート認証局サーバーのルート証明書の追加
```sh
if [ -f /opt/ca/federated-roots/peer_root_ca.crt ]; then
  sudo install -m 700 -o "step-ca" -g "step-ca" "/opt/ca/federated-roots/peer_root_ca.crt" "/opt/step-ca/certs/peer_root_ca.crt" &&
  sudo apt-get install -y jq &&
  TARGET_FILEPATH="/opt/step-ca/config/ca.json" &&
  sudo -u "step-ca" cat "${TARGET_FILEPATH}" | \
    jq ". + {\"federatedRoots\": [\"${STEPCA_CONTAINER_DATAPATH}/certs/peer_root_ca.crt\"]}" | \
    sudo -u "step-ca" tee "${TARGET_FILEPATH}.tmp" > /dev/null &&
  sudo -u "step-ca" mv "${TARGET_FILEPATH}.tmp" "${TARGET_FILEPATH}" &&
  sudo -u "step-ca" chmod 644 "${TARGET_FILEPATH}"
fi
```
- [Step v0.8.3: Federation and Root Rotation for step Certificates](https://smallstep.com/blog/step-v0.8.3-federation-root-rotation/)

### 【オプション】X5Cプロビジョナーの追加
#### 追加
```sh
sudo find "/opt/step-ca/certs" -type f -name "*root_ca*.crt" -exec cat {} + | \
  sudo tee "/opt/step-ca/certs/federation.crt" > /dev/null &&
sudo podman run \
  --user "$(id -u step-ca):$(id -g step-ca)" \
  --interactive --tty \
  --userns=keep-id \
  --volume "/opt/step-ca:${STEPCA_CONTAINER_DATAPATH}:Z" \
  docker.io/smallstep/step-ca \
    step ca provisioner add x5c-provisioner \
      --type=X5C \
      --x5c-roots "${STEPCA_CONTAINER_DATAPATH}/certs/root_ca.crt"
      # "${STEPCA_CONTAINER_DATAPATH}/certs/federation.crt"
```

#### 【デバッグ】X5Cプロビジョナーの確認
```sh
wget -O - https://localhost:8443/provisioners
```

#### 【元に戻す】X5Cプロビジョナーの削除
```sh
sudo podman run \
  --user "$(id -u step-ca):$(id -g step-ca)" \
  --interactive --tty \
  --userns=keep-id \
  --volume "/opt/step-ca:${STEPCA_CONTAINER_DATAPATH}:Z" \
  docker.io/smallstep/step-ca \
    step ca provisioner remove x5c
```
以下のエラーが出てうまくいかない。
```
Something unexpected happened.
If you want to help us debug the problem, please run:
STEPDEBUG=1 step ca provisioner remove x5c
and send the output to info@smallstep.com
```

### 【デバッグ】step-caの確認
#### ファイルリスト
```sh
cd / &&
sudo -u "step-ca" find "/opt/step-ca" -exec ls -ld {} +
```
`find`コマンドは、カレントディレクトリーに実行権限がないと、カレントディレクトリーに対して「Permission denied」エラーとなるため、カレントディレクトリーを`/`にしている。

#### 設定
```sh
sudo -u "step-ca" cat "/opt/step-ca/config/ca.json"
sudo -u "step-ca" cat "/opt/step-ca/config/defaults.json"
```

#### 秘密鍵
```sh
sudo -u "step-ca" cat "/opt/step-ca/secrets/intermediate_ca_key"
```

#### 証明書
```sh
sudo -u "step-ca" openssl x509 -text -noout -in "/opt/step-ca/certs/root_ca.crt"
sudo -u "step-ca" openssl x509 -text -noout -in "/opt/step-ca/certs/intermediate_ca.crt"
```

#### SSHホスト秘密鍵
```sh
sudo -u "step-ca" cat "/opt/step-ca/secrets/ssh_host_ca_key"
```

### 【元に戻す】削除
```sh
sudo rm -dr "/opt/step-ca"
```

## サービス化
### サービスの作成・起動
```sh
sudo tee "/etc/containers/systemd/step-ca.container" << EOS > /dev/null &&
[Container]
Image=docker.io/smallstep/step-ca
ContainerName=step-ca
AutoUpdate=registry
LogDriver=journald

PublishPort=8443:8443
Volume=/opt/step-ca:${STEPCA_CONTAINER_DATAPATH}:Z
User=$(id -u step-ca)
Group=$(id -g step-ca)
UserNS=keep-id

[Service]
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOS
sudo systemctl daemon-reload &&
sudo systemctl start step-ca.service
```

### 【デバッグ】サービスの状態の確認
```sh
sudo systemctl status --no-pager --full step-ca.service
```

### 【デバッグ】ログの確認
```sh
journalctl --no-pager --lines=20 --unit=step-ca.service
```

### 【デバッグ】HTTPSの確認
```sh
wget -O - https://localhost:8443/health
```

### 【デバッグ】再起動
```sh
sudo systemctl restart step-ca.service
```

### 【元に戻す】停止・削除
```sh
sudo systemctl stop step-ca.service &&
sudo rm /etc/containers/systemd/step-ca.container &&
sudo systemctl daemon-reload
```

## step-cli（クライアント）で使うルートCA証明書のフィンガープリントを表示
```sh
openssl x509 -noout -fingerprint -sha256 -in "/usr/local/share/ca-certificates/private-ca.crt" | cut -d '=' -f 2 | tr -d ':'
```
