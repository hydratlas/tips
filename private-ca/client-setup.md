# step-cli（クライアント）
## 変数の準備
```sh
fingerprints=("abc" "abc") &&
hostnames=("ca-01.home.arpa" "ca-02.home.arpa") &&
ports=("8443" "8443")
```

## インストール
### Debian系
```sh
wget https://dl.smallstep.com/cli/docs-cli-install/latest/step-cli_amd64.deb &&
sudo dpkg -i step-cli_amd64.deb &&
rm step-cli_amd64.deb
```

## コマンドラインリファレンス
[step ca federation](https://smallstep.com/docs/step-cli/reference/)

## ルートCA証明書を取得
```sh
root_crt_path="/usr/local/share/ca-certificates/private-ca.crt" &&
root_crt_temp_path="/usr/local/share/ca-certificates/private-ca-temp.crt" &&
length=${#hostnames[@]} &&
for ((i=0; i<length; i++)); do
  fingerprint=${fingerprints[$i]} &&
  hostname=${hostnames[$i]} &&
  port=${ports[$i]} &&
  sudo step ca root "${root_crt_temp_path}" \
    --ca-url "https://${hostname}:${port}" \
    --fingerprint "${fingerprint}" \
    --force &&
  sudo chmod 644 "${root_crt_temp_path}" &&
  sudo step ca federation "${root_crt_path}" \
    --ca-url "https://${hostname}:${port}" \
    --root "${root_crt_temp_path}" \
    --force &&
  sudo chmod 644 "${root_crt_path}" &&
  sudo rm "${root_crt_temp_path}" &&
  openssl crl2pkcs7 -nocrl -certfile "${root_crt_path}" | openssl pkcs7 -print_certs -noout
done &&
sudo update-ca-certificates
```

### 【デバッグ】HTTPSの確認
```sh
length=${#hostnames[@]} &&
for ((i=0; i<length; i++)); do
  hostname=${hostnames[$i]} &&
  port=${ports[$i]} &&
  wget -O - "https://${hostname}:${port}/health"
done
```

## サーバー証明書の作成（複数ドメイン対応）
```sh
crt_dir="/etc/ssl/certs" &&
key_dir="/etc/ssl/private" &&
length=${#hostnames[@]} &&
for ((i=0; i<length; i++)); do
  hostname=${hostnames[$i]} &&
  port=${ports[$i]} &&
  hosts=($(hostname -A | tr ' ' '\n' | grep -Ff <(grep '^search' /etc/resolv.conf | awk '{$1=""; print $0}' | sed 's/^ *//' | tr -s ' ' | tr ' ' '\n') | grep -Fv ".vip.")) &&
  sudo step ca certificate \
    "${hosts[0]}" "${crt_dir}/$(hostname)-${hostname}.crt" "${key_dir}/$(hostname)-${hostname}.key" \
    --provisioner acme \
    --ca-url "https://${hostname}:${port}" \
    --root "/usr/local/share/ca-certificates/private-ca.crt" \
    --force \
    ${hosts[@]/#/--san } &&
  sudo chmod 644 "${crt_dir}/$(hostname)-${hostname}.crt" &&
  sudo chmod 600 "${key_dir}/$(hostname)-${hostname}.key" &&
  sudo install -m 644 "${crt_dir}/$(hostname)-${hostname}.crt" "${crt_dir}/$(hostname).crt" &&
  sudo install -m 600 "${key_dir}/$(hostname)-${hostname}.key" "${key_dir}/$(hostname).key"
done
```
`.vip.`を含むものは除外している（仮想IPアドレスに対応するドメインにはサブドメインとして「vip」を含むようにすることを想定）。

## 【デバッグ】証明書の概要の確認
```sh
openssl x509 -text -noout -in "${crt_path}"
```

## 【デバッグ】証明書のチェーンの確認
```sh
openssl crl2pkcs7 -nocrl -certfile "${crt_path}" | openssl pkcs7 -print_certs -noout
```

## 証明書の更新
```sh
crt_dir="/etc/ssl/certs" &&
key_dir="/etc/ssl/private" &&
length=${#hostnames[@]} &&
for ((i=0; i<length; i++)); do
  hostname=${hostnames[$i]} &&
  port=${ports[$i]} &&
  hosts=($(hostname -A | tr ' ' '\n' | grep -Ff <(grep '^search' /etc/resolv.conf | awk '{$1=""; print $0}' | sed 's/^ *//' | tr -s ' ' | tr ' ' '\n') | grep -Fv ".vip.")) &&
  sudo step ca renew \
    "${crt_dir}/$(hostname)-${hostname}.crt" "${key_dir}/$(hostname)-${hostname}.key" \
    --ca-url "https://${hostname}:${port}" \
    --root "/usr/local/share/ca-certificates/private-ca.crt" \
    --force &&
  if test "${crt_dir}/$(hostname)-${hostname}.crt" -nt "${crt_dir}/$(hostname).crt"; then
    sudo install -m 644 "${crt_dir}/$(hostname)-${hostname}.crt" "${crt_dir}/$(hostname).crt"
  fi &&
  if test "${key_dir}/$(hostname)-${hostname}.key" -nt "${key_dir}/$(hostname).key"; then
    sudo install -m 600 "${key_dir}/$(hostname)-${hostname}.key" "${key_dir}/$(hostname).key"
  fi
done
```

## サーバー証明書の更新のサービス化
### スクリプトファイルの作成
```sh
length=${#urls[@]} &&
hostnames_output="" &&
for element in "${hostnames[@]}"; do
  escaped_element="$(printf '%q' "${element}")" &&
  hostnames_output+="\"${escaped_element}\" "
done &&
ports_output="" &&
for element in "${ports[@]}"; do
  escaped_element="$(printf '%q' "${element}")" &&
  ports_output+="\"${escaped_element}\" "
done &&
sudo tee "/usr/local/bin/step-ca-renew" << EOS > /dev/null &&
#!/bin/bash
hostnames=(${hostnames_output})
ports=(${ports_output})
root_crt_path="/usr/local/share/ca-certificates/private-ca.crt"
crt_dir="/etc/ssl/certs"
key_dir="/etc/ssl/private"
length=\${#hostnames[@]}
for ((i=0; i<length; i++)); do
  hostname=\${hostnames[\$i]} &&
  port=\${ports[\$i]} &&
  step ca federation "\${root_crt_path}" \
    --ca-url "https://\${hostname}:\${port}" \
    --root "\${root_crt_path}" \
    --force &&
  chmod 644 "\${root_crt_path}"
  update-ca-certificates
  hosts=(\$(hostname -A | tr ' ' '\n' | grep -Ff <(grep '^search' /etc/resolv.conf | awk '{\$1=""; print \$0}' | sed 's/^ *//' | tr -s ' ' | tr ' ' '\n') | grep -Fv ".vip.")) &&
  step ca renew \
    "\${crt_dir}/\$(hostname)-\${hostname}.crt" "\${key_dir}/\$(hostname)-\${hostname}.key" \
    --ca-url "https://\${hostname}:\${port}" \
    --root "/usr/local/share/ca-certificates/private-ca.crt" \
    --force &&
  if test "\${crt_dir}/\$(hostname)-\${hostname}.crt" -nt "\${crt_dir}/\$(hostname).crt"; then
    install -m 644 "\${crt_dir}/\$(hostname)-\${hostname}.crt" "\${crt_dir}/\$(hostname).crt"
  fi &&
  if test "\${key_dir}/\$(hostname)-\${hostname}.key" -nt "\${key_dir}/\$(hostname).key"; then
    install -m 600 "\${key_dir}/\$(hostname)-\${hostname}.key" "\${key_dir}/\$(hostname).key"
  fi
done
EOS
sudo chmod 755 "/usr/local/bin/step-ca-renew"
```

### スクリプトファイルの動作確認
```sh
sudo bash /usr/local/bin/step-ca-renew
sudo bash -x /usr/local/bin/step-ca-renew
```

### サービスおよびタイマーファイルの作成
```sh
sudo tee "/etc/systemd/system/step-ca-renew.service" << EOS > /dev/null &&
[Unit]
Description=Renew ACME certificate using Step CA renewal process
Wants=network-online.target
After=network-online.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/step-ca-renew
StandardOutput=journal
StandardError=journal
EOS
sudo tee "/etc/systemd/system/step-ca-renew.timer" << EOS > /dev/null &&
[Unit]
Description=Trigger Step CA certificate renewal periodically

[Timer]
OnCalendar=*-*-* 00,12:00:00
Persistent=true
RandomizedDelaySec=11h
Unit=step-ca-renew.service

[Install]
WantedBy=timers.target
EOS
sudo systemctl daemon-reload &&
sudo systemctl enable --now step-ca-renew.timer &&
sudo systemctl status --no-pager --full step-ca-renew.service &&
sudo systemctl status --no-pager --full step-ca-renew.timer
```

## 【デバッグ】サーバー証明書の更新のサービスのログを確認
```sh
journalctl --no-pager --lines=20 --unit=step-ca-renew.service
journalctl --no-pager --lines=20 --unit=step-ca-renew.timer
```

## 【元に戻す】サーバー証明書の更新のサービス化
```sh
sudo systemctl disable --now step-ca-renew.timer &&
sudo rm "/etc/systemd/system/step-ca-renew.timer" &&
sudo rm "/etc/systemd/system/step-ca-renew.service" &&
sudo systemctl daemon-reload
```
