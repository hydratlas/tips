# step-ca（サーバー）
## 準備
Podmanをインストールしておく。

## 変数の準備
```sh
sudo install -m 755 -o "root" -g "root" /dev/stdin "/opt/ca/ca.env" << EOS > /dev/null
user_name="step-ca"
ca_dir="/opt/ca"
step_ca_dir="/opt/step-ca"
ca_container_dir="/home/ca"
step_ca_container_dir="/home/step"
PROVISIONER_PASSWORD_FILENAME="provisioner-password"
PASSWORD_FILENAME="password"
EOS
```

## ルートCA証明書の作成
### ユーザーおよびディレクトリーの作成
```sh
source "/opt/ca/ca.env" &&
if ! id "${user_name}" &>/dev/null; then
  sudo useradd --system --no-create-home --user-group --shell /usr/sbin/nologin "${user_name}"
fi &&
sudo install -o "root" -g "${user_name}" -m 775 -d "${ca_dir}/root" "${ca_dir}/federated-roots"
```

### 秘密鍵の作成
```sh
source "/opt/ca/ca.env" &&
OUT_FILEPATH="${ca_dir}/root/root_ca_key" &&
sudo -u "${user_name}" openssl genpkey -algorithm ED25519 -out "${OUT_FILEPATH}" &&
sudo chmod 640 "${OUT_FILEPATH}" &&
sudo chown "root:${user_name}" "${OUT_FILEPATH}"
```

### 設定ファイルの作成
```sh
source "/opt/ca/ca.env" &&
sudo install -m 644 -o "root" -g "${user_name}" /dev/stdin "${ca_dir}/root/openssl.cnf" << EOS > /dev/null
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
source "/opt/ca/ca.env" &&
OUT_FILEPATH="${ca_dir}/root/root_ca.crt" &&
sudo -u "${user_name}" openssl req -x509 -new \
  -key "${ca_dir}/root/root_ca_key" -nodes \
  -out "${OUT_FILEPATH}" \
  -subj "/O=Private $(hostname)/CN=Private $(hostname) Root CA" \
  -days 7300 \
  -config "${ca_dir}/root/openssl.cnf" &&
sudo chmod 644 "${OUT_FILEPATH}" &&
sudo chown "root:${user_name}" "${OUT_FILEPATH}"
```

### 【オプション】ほかのプライベート認証局サーバーのルート証明書の追加
#### ファイルの作成
```sh
source "/opt/ca/ca.env" &&
OUT_FILEPATH="${ca_dir}/federated-roots/peer_root_ca.crt" &&
sudo -u "${user_name}" touch "${OUT_FILEPATH}" &&
sudo chmod 644 "${OUT_FILEPATH}" &&
sudo chown "root:${user_name}" "${OUT_FILEPATH}"
```

#### ファイルの編集
```sh
sudo nano "${OUT_FILEPATH}"
```
ほかのサーバーで`cat /opt/ca/root/root_ca.crt`コマンドを実行し表示された内容を入力する。

### 【デバッグ】確認
#### 秘密鍵の表示
```sh
source "/opt/ca/ca.env" &&
sudo -u "${user_name}" cat "${ca_dir}/root/root_ca_key"
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
source "/opt/ca/ca.env" &&
sudo rm -dr "${ca_dir}" &&
sudo userdel "${user_name}"
```

## step-caのインストール
### 変数の設定、ならびにユーザーおよびディレクトリーの作成
```sh
source "/opt/ca/ca.env" &&
sudo install -o "root" -g "${user_name}" -m 775 -d "${step_ca_dir}" &&
sudo install -o "${user_name}" -g "${user_name}" -m 700 -d "${step_ca_dir}/secrets"
```

### step-caのインストール
```sh
source "/opt/ca/ca.env" &&
OUT_FILEPATH="${step_ca_dir}/secrets/${PROVISIONER_PASSWORD_FILENAME}" &&
sudo -u "${user_name}" openssl rand -base64 -out "${OUT_FILEPATH}" 32 &&
sudo chmod 600 "${OUT_FILEPATH}" &&
sudo chown "${user_name}:${user_name}" "${OUT_FILEPATH}" &&
OUT_FILEPATH="${step_ca_dir}/secrets/${PASSWORD_FILENAME}" &&
sudo -u "${user_name}" openssl rand -base64 -out "${OUT_FILEPATH}" 32 &&
sudo chmod 600 "${OUT_FILEPATH}" &&
sudo chown "${user_name}:${user_name}" "${OUT_FILEPATH}" &&
sudo podman run \
  --user "$(id -u "${user_name}"):$(id -g "${user_name}")" \
  --interactive --tty \
  --volume "${step_ca_dir}:${step_ca_container_dir}:Z" \
  --volume "/opt/ca:${ca_container_dir}:ro,z" \
  docker.io/smallstep/step-ca \
    step ca init \
    --deployment-type="standalone" \
    --name="Private $(hostname)" \
    --dns="$(hostname -A | tr ' ' '\n' | grep -F '.' | paste -sd ',' -),localhost" \
    --address=":8443" \
    --root="${ca_container_dir}/root/root_ca.crt" \
    --key="${ca_container_dir}/root/root_ca_key" \
    --password-file="${step_ca_container_dir}/secrets/${PASSWORD_FILENAME}" \
    --provisioner="admin" \
    --provisioner-password-file="${step_ca_container_dir}/secrets/${PROVISIONER_PASSWORD_FILENAME}" \
    --acme \
    --ssh \
    --remote-management
```

### 【オプション】ほかのプライベート認証局サーバーのルート証明書の追加
```sh
source "/opt/ca/ca.env" &&
if [ -f "${ca_dir}${ca_dir}s/federated-roots/peer_root_ca.crt" ]; then
  sudo install -m 700 -o "${user_name}" -g "${user_name}" "${ca_dir}/federated-roots/peer_root_ca.crt" "${step_ca_dir}/certs/peer_root_ca.crt" &&
  sudo apt-get install -y jq &&
  TARGET_FILEPATH="${step_ca_dir}/config/ca.json" &&
  sudo -u "${user_name}" cat "${TARGET_FILEPATH}" | \
    jq ". + {\"federatedRoots\": [\"${step_ca_container_dir}/certs/peer_root_ca.crt\"]}" | \
    sudo -u "${user_name}" tee "${TARGET_FILEPATH}.tmp" > /dev/null &&
  sudo -u "${user_name}" mv "${TARGET_FILEPATH}.tmp" "${TARGET_FILEPATH}" &&
  sudo -u "${user_name}" chmod 644 "${TARGET_FILEPATH}"
fi
```
- [Step v0.8.3: Federation and Root Rotation for step Certificates](https://smallstep.com/blog/step-v0.8.3-federation-root-rotation/)

### 【オプション】X5Cプロビジョナーの追加
#### 追加
```sh
source "/opt/ca/ca.env" &&
sudo find "${step_ca_dir}/certs" -type f -name "*root_ca*.crt" -exec cat {} + | \
  sudo tee "${step_ca_dir}/certs/federation.crt" > /dev/null &&
sudo podman run \
  --user "$(id -u "${user_name}"):$(id -g "${user_name}")" \
  --interactive --tty \
  --volume "${step_ca_dir}:${step_ca_container_dir}:Z" \
  docker.io/smallstep/step-ca \
    step ca provisioner add x5c \
      --type=X5C \
      --x5c-roots "${step_ca_container_dir}/certs/root_ca.crt"
      # "${step_ca_container_dir}/certs/federation.crt"
```

#### 【デバッグ】X5Cプロビジョナーの確認
```sh
wget -O - https://localhost:8443/provisioners
```

#### 【元に戻す】X5Cプロビジョナーの削除
```sh
sudo podman run \
  --user "$(id -u "${user_name}"):$(id -g "${user_name}")" \
  --interactive --tty \
  --volume "${step_ca_dir}:${STEPCA_CONTAINER_DATAPATH}:Z" \
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
sudo -u "${user_name}" find "${step_ca_dir}" -exec ls -ld {} +
```
`find`コマンドは、カレントディレクトリーに実行権限がないと、カレントディレクトリーに対して「Permission denied」エラーとなるため、カレントディレクトリーを`/`にしている。

#### 設定
```sh
sudo -u "${user_name}" cat "${step_ca_dir}/config/ca.json"
sudo -u "${user_name}" cat "${step_ca_dir}/config/defaults.json"
```

#### 秘密鍵
```sh
sudo -u "${user_name}" cat "${step_ca_dir}/secrets/intermediate_ca_key"
```

#### 証明書
```sh
sudo -u "${user_name}" openssl x509 -text -noout -in "${step_ca_dir}/certs/root_ca.crt"
sudo -u "${user_name}" openssl x509 -text -noout -in "${step_ca_dir}/certs/intermediate_ca.crt"
```

#### SSHホスト秘密鍵
```sh
sudo -u "${user_name}" cat "${step_ca_dir}/secrets/ssh_host_ca_key"
```

### 【元に戻す】削除
```sh
sudo rm -dr "${step_ca_dir}"
```

## サービス化
### サービスの作成・起動
```sh
source "/opt/ca/ca.env" &&
sudo tee "/etc/containers/systemd/step-ca.container" << EOS > /dev/null &&
[Container]
Image=docker.io/smallstep/step-ca
ContainerName=step-ca
AutoUpdate=registry
LogDriver=journald

PublishPort=8443:8443
Volume=${step_ca_dir}:${step_ca_container_dir}:Z
User=$(id -u "${user_name}")
Group=$(id -g "${user_name}")

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
