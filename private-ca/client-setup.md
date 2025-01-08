# step-cli（クライアント）
## インストール
### Debian系
```sh
wget https://dl.smallstep.com/cli/docs-cli-install/latest/step-cli_amd64.deb &&
sudo dpkg -i step-cli_amd64.deb &&
rm step-cli_amd64.deb
```

## 変数の準備
```sh
FINGERPRINT="..." &&
CA_HOSTNAME="ca-01.int.home.arpa"
```

## 初期設定
```sh
sudo step ca bootstrap \
  --ca-url "https://${CA_HOSTNAME}:8443" \
  --fingerprint "${FINGERPRINT}" \
  --install \
  --force \
  --context "${CA_HOSTNAME}"
```

### 【デバッグ】HTTPSの確認
```sh
wget -O - "https://${CA_HOSTNAME}:8443/health"
```

## 初期設定の削除
```sh
sudo rm -dr /root/.step
```

## サーバー証明書の作成（複数ドメイン対応）
```sh
hostnames=($(hostname -A | tr ' ' '\n' | grep -Ff <(grep '^search' /etc/resolv.conf | awk '{$1=""; print $0}' | sed 's/^ *//' | tr -s ' ' | tr ' ' '\n') | grep -Fv ".vip.")) &&
sudo step ca certificate \
  "${hostnames[0]}" "/etc/ssl/certs/server.${CA_HOSTNAME}.crt" "/etc/ssl/private/server.${CA_HOSTNAME}.key" \
  --provisioner acme \
  --force \
  --context "${CA_HOSTNAME}" \
  ${hostnames[@]/#/--san }
```
`.vip.`を含むものは除外している（仮想IPアドレスに対応するドメインにはサブドメインとして「vip」を含むようにすることを想定）。

## 証明書の概要の確認
```sh
sudo openssl x509 -text -noout -in "/etc/ssl/certs/server.${CA_HOSTNAME}.crt"
```

## サーバー証明書の更新
```sh
sudo step ca renew "/etc/ssl/certs/server.${CA_HOSTNAME}.crt" "/etc/ssl/private/server.${CA_HOSTNAME}.key" --force --context "${CA_HOSTNAME}"
```

## サーバー証明書の更新のサービス化
```sh
sudo tee "/etc/systemd/system/step-ca-renew.${CA_HOSTNAME}.service" << EOS > /dev/null &&
[Unit]
Description=Step CA Certificate Renewal Service
After=network-online.target
Wants=network-online.target

[Service]
ExecStart=/usr/bin/step ca renew "/etc/ssl/certs/server.${CA_HOSTNAME}.crt" "/etc/ssl/private/server.${CA_HOSTNAME}.key" --daemon --context "${CA_HOSTNAME}"
Restart=always
KillSignal=SIGINT

[Install]
WantedBy=multi-user.target
EOS
sudo systemctl daemon-reload &&
sudo systemctl enable --now "step-ca-renew.${CA_HOSTNAME}.service" &&
sudo systemctl status --no-pager --full step-ca-renew.${CA_HOSTNAME}.service
```

## 【元に戻す】サーバー証明書の更新のサービス化
```sh
sudo systemctl disable --now "step-ca-renew.${CA_HOSTNAME}.service" &&
sudo rm "/etc/systemd/system/step-ca-renew.${CA_HOSTNAME}.service" &&
sudo systemctl daemon-reload
```
