# Kanidm Clientのセットアップ
## 自己署名証明書を設定
### プライベート認証局の証明書をコピー
サーバー側では例えば`cat /opt/ca/ca.crt`コマンドで証明書を表示する。
```sh
FILEPATH="/usr/local/share/ca-certificates/ca.crt" &&
sudo tee "${FILEPATH}" << EOS > /dev/null &&
...
EOS
sudo chmod 644 "${FILEPATH}"
```

### サーバーの証明書をコピー
サーバー側では例えば`cat /opt/kanidm/idm-server.crt`コマンドで証明書を表示する。
```sh
FILEPATH="/usr/local/share/ca-certificates/idm-server.crt" &&
sudo tee "${FILEPATH}" << EOS > /dev/null &&
...
EOS
sudo chmod 644 "${FILEPATH}"
```

### システムに証明書をインストール
```sh
sudo update-ca-certificates
```

## リポジトリーの設定
```sh
wget -q -O - "https://kanidm.github.io/kanidm_ppa/kanidm_ppa.asc" | \
  sudo tee /usr/share/keyrings/kanidm_ppa.asc > /dev/null &&
sudo tee "/etc/apt/sources.list.d/kanidm_ppa.sources" > /dev/null << EOF
Types: deb
URIs: https://kanidm.github.io/kanidm_ppa
Suites: $(grep -oP '(?<=^VERSION_CODENAME=).+(?=$)' /etc/os-release)
Components: stable
Signed-By: /usr/share/keyrings/kanidm_ppa.asc
Architectures: $(dpkg --print-architecture)
EOF
```

## パッケージをインストール・設定
```sh
sudo apt-get install -U -y kanidm &&
sudo mkdir -p "/etc/kanidm" &&
sudo tee "/etc/kanidm/config" > /dev/null << EOF
uri = "https://idm-01.int.home.arpa:8443"
ca_path = "/usr/local/share/ca-certificates/idm-01-server.crt"
#verify_hostnames = false
#verify_ca = false
EOF
```

## HTTPS接続の確認
```sh
wget --debug -O - https://idm-01.int.home.arpa:8443
```

## テスト実行
```sh
kanidm self whoami --name anonymous

kanidm logout --name anonymous
```
