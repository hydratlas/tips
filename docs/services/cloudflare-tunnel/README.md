# Cloudflare Tunnel
[Create a remotely-managed tunnel (dashboard) · Cloudflare Zero Trust docs](https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/get-started/create-remote-tunnel/)

## Cloudflareの前設定
ダッシュボードの「Zero Trust」→「Networks」→「Tunnels」を開いて、トンネルを作成する。dockerコマンドによるインストール方法を表示して、トークンを取得する。

## インストール・サービスの起動
`token`変数は適宜書き換える。
```sh
token="abc" &&
container_user="cloudflared" &&
if hash apt-get 2>/dev/null; then
  sudo apt-get install -y podman
elif hash dnf 2>/dev/null; then
  sudo dnf install -y podman
fi &&
sudo tee /etc/sysctl.d/99-ping-group-range.conf << EOS > /dev/null &&
net.ipv4.ping_group_range=0 2147483647
EOS
sudo sysctl --system &&
if ! id "${container_user}" &>/dev/null; then
    sudo useradd --system --user-group --add-subids-for-system \
      --shell /sbin/nologin --create-home "${container_user}"
fi &&
sudo usermod -aG systemd-journal "${container_user}" &&
user_home="$(grep "^${container_user}:" /etc/passwd | cut -d: -f6)" &&
sudo loginctl enable-linger "${container_user}" &&
sudo -u "${container_user}" mkdir -p "${user_home}/.config/containers/systemd" &&
sudo install \
  -m 700 -o "${container_user}" -g "${container_user}" \
  /dev/stdin "${user_home}/.config/containers/systemd/cloudflared.env" << EOS > /dev/null &&
TUNNEL_TOKEN=${token}
NO_AUTOUPDATE=true
EOS
sudo install \
  -m 644 -o "${container_user}" -g "${container_user}" \
  /dev/stdin \
  "${user_home}/.config/containers/systemd/cloudflared.container" << EOS > /dev/null &&
[Container]
Image=docker.io/cloudflare/cloudflared:latest
ContainerName=cloudflared
AutoUpdate=registry
LogDriver=journald
EnvironmentFile=%h/.config/containers/systemd/cloudflared.env

Exec=tunnel run

[Service]
Restart=on-failure

[Install]
WantedBy=default.target
EOS
sleep 1s &&
sudo -u "${container_user}" env XDG_RUNTIME_DIR=/run/user/$(id -u "${container_user}") \
  systemctl --user daemon-reexec &&
sleep 1s &&
sudo -u "${container_user}" env XDG_RUNTIME_DIR=/run/user/$(id -u "${container_user}") \
  systemctl --user daemon-reload &&
sudo -u "${container_user}" env XDG_RUNTIME_DIR=/run/user/$(id -u "${container_user}") \
  systemctl --user start cloudflared.service &&
sudo -u "${container_user}" env XDG_RUNTIME_DIR=/run/user/$(id -u "${container_user}") \
  systemctl --user status --no-pager --full cloudflared.service
```
非ルートユーザーの場合、`WantedBy=multi-user.target`だと再起動後にサービスが起動しない。`WantedBy=default.target`にする必要がある。

## 自動更新の有効化
```sh
container_user="cloudflared" &&
sudo -u "${container_user}" env XDG_RUNTIME_DIR=/run/user/$(id -u "${container_user}") \
  systemctl --user enable --now podman-auto-update.timer
sudo -u "${container_user}" env XDG_RUNTIME_DIR=/run/user/$(id -u "${container_user}") \
  systemctl --user status --no-pager --full podman-auto-update.timer
```

## 【デバッグ】ログの確認
```sh
container_user="cloudflared" &&
sudo -u "${container_user}" journalctl --user --no-pager --lines=100 --unit=cloudflared.service
```

## 【デバッグ】再起動
```sh
container_user="cloudflared" &&
sudo -u "${container_user}" env XDG_RUNTIME_DIR=/run/user/$(id -u "${container_user}") \
  systemctl --user restart cloudflared.service
```

## 【元に戻す】停止・削除
```sh
container_user="cloudflared" &&
sudo -u "${container_user}" env XDG_RUNTIME_DIR=/run/user/$(id -u "${container_user}") \
  systemctl --user stop cloudflared.service &&
user_home="$(grep "^${container_user}:" /etc/passwd | cut -d: -f6)" &&
sudo rm "${user_home}/.config/containers/systemd/cloudflared.container" &&
sudo -u "${container_user}" env XDG_RUNTIME_DIR=/run/user/$(id -u "${container_user}") \
  systemctl --user daemon-reload &&
sudo rm "${user_home}/.config/containers/systemd/cloudflared.env"
```

## Cloudflareの後設定
### HTTPS
ダッシュボードの「Zero Trust」→「Networks」→「Tunnels」を開いて、トンネルの設定画面を表示する。上部に「Overview」、「Public Hostname」および「Private Network」という3つのタブが表示されるため、「Public Hostname」を選択する。

追加ボタンを押し「Subdomain」、「Domain」および「Path」に外部に公開するURLを指定する。また、「Type」および「URL」に内部のアクセス先を指定する。このとき「Path」は内部のアクセス先にも影響するため注意（つまり内部のアクセス先のパスを限定する機能ということである）。

HTTPSの場合にはTLS設定として「No TLS Verify」が選べる。内部ではTLSの証明書を設定しない場合も多いが、その場合はオンにする。

### SSH
#### 1. サーバーをCloudflareに接続
ダッシュボードの「Zero Trust」→「Networks」→「Tunnels」を開いて、トンネルの設定画面を表示する。上部に「Overview」、「Public Hostname」および「Private Network」という3つのタブが表示されるため、「Private Network」を選択する。

追加ボタンを押し「CIDR」にSSHサーバーのIPアドレスと「/32」を入力して（例：192.168.1.2/32）、保存する。

### 2. ゲートウェイプロキシの有効化
ダッシュボードの「Zero Trust」→「Settings」→「Network」を開く。「Firewall」設定群の中の「Proxy」をオンにする。TCPのチェックはデフォルトで入っているので、それを確認する。

### 3. デバイス登録ルールの作成
ダッシュボードの「Zero Trust」→「Settings」→「WARP Client」を開いて、「Device enrollment permissions」の「Manage」ボタンを押す。「Device enrollment permissions」画面が表示されるので、「Add a rule」ボタンを押し、任意の名前と「Selector」は「Country」、「Value」は「Japan」と入力して、保存する。

### 4. WARPを介してサーバーIPをルーティングする
ダッシュボードの「Zero Trust」→「Settings」→「WARP Client」から、「Device settings」の中の「Default」の設定を変更する。「Split Tunnels」の「Manage」ボタンを押す。除外されているIPアドレスの一覧が出てくるので、SSHサーバーのIPアドレスが含まれるものを削除する。この削除操作は保存を明示的にする必要はない。

### 5. ターゲットの追加
ダッシュボードの「Zero Trust」→「Networks」→「Targets」を開いて、ターゲットを追加する。ターゲットのホスト名とIPアドレスを入力する。

### 6. インフラストラクチャーアプリケーションの追加
ダッシュボードの「Zero Trust」→「Access」→「Applications」から、「Infrastructure」タイプのアプリケーションを追加する。

アプリケーション名は「SSH jump」として、「Target criteria」の「target hostname」にはさきほど追加したターゲットを指定する。ポートは22、プロトコルはSSHとする。そして、「Next」ボタンを押す。

ポリシーの追加画面に移るので、「Policy name」には「SSH jump」と入力し、「Configure rules」の「Selector」には「Emails」を選択し、「Value」にはアクセスを許可したいメールアドレスを入力する。「Connection context」の「SSH user」にはSSHサーバーにおいて、ユーザーがログインできるUNIXユーザー名を入力する。そして、「Next」ボタンを押すと、完了する。

### 7. APIトークンの作成
ダッシュボードの「Manage Account」→「API Tokens」を開いて、トークンを作成する。テンプレートを使用するか、カスタムトークンを作成するか聞かれるためカスタムトークンを選ぶ。

「Token name」には「SSH jump」と入力し、「Permissions」には「Account」、「Access: SSH Auditing」および「Edit」と入力または選択する。「Continue to summary」ボタンを押すと、概要を確認する画面に移る。「Create Token」ボタンを押して完了させる。完了すると、作成したトークンが表示されるため、記録しておく（一度しか表示されないため注意）。

ダッシュボードのホーム画面のURIが<https://dash.cloudflare.com/{account_id}>とアカウントIDを含むため、アカウントIDを記録する。

### 8. 公開鍵の取得と保存
SSHサーバー上で、トークンとアカウントIDを使って、`public_key`を取得する。`<API_TOKEN>`と`{account_id}`は記録しておいた値で書き換える。
```sh
wget -O - \
  --method=POST \
  --header="Authorization: Bearer <API_TOKEN>" \
  "https://api.cloudflare.com/client/v4/accounts/{account_id}/access/gateway_ca"
```

2回目の取得の際はHTTPのPOSTメソッドではなくGETメソッドで取得する。
```sh
wget -O - \
  --header="Authorization: Bearer <API_TOKEN>" \
  "https://api.cloudflare.com/client/v4/accounts/{account_id}/access/gateway_ca"
```

以下のコマンドで取得した公開鍵をファイルに書き込む。
```sh
sudo install \
  -m 600 -o "root" -g "root" \
  /dev/stdin "/etc/ssh/ca.pub" << EOS > /dev/null
ecdsa-sha2-nistp256 <redacted> open-ssh-ca@cloudflareaccess.org
EOS
```

### 9. SSHサーバーの設定を変更する
SSHサーバー上で、以下のコマンドを実行する。
```sh
sudo mkdir -p "/etc/ssh/sshd_config.d" &&
sudo install \
  -m 644 -o "root" -g "root" \
  /dev/stdin "/etc/ssh/sshd_config.d/pubkey_ca.conf" << EOS > /dev/null &&
PubkeyAuthentication yes
TrustedUserCAKeys /etc/ssh/ca.pub
EOS
UNIT_NAME="ssh.service" &&
if systemctl list-unit-files | grep -q "^${UNIT_NAME}" && systemctl is-active --quiet "${UNIT_NAME}"; then
  sudo systemctl reload "${UNIT_NAME}"
fi
```

### 10. デバイスをCloudflareに接続
「Zero Trust」→「Settings」→「Custom Pages」から、表示されるチーム名（*.cloudflareaccess.com）を記録しておく。

クライアントにWARPをインストールする。ダウンロード先はGUIの場合は[Download WARP · Cloudflare Zero Trust docs](https://developers.cloudflare.com/cloudflare-one/connections/connect-devices/warp/download-warp/)、CUIの場合は[Cloudflare WARP packages](https://pkg.cloudflareclient.com/)である。

インストールしたら、「設定」→「アカウント」からZero Trustに接続する。その際、記録しておいたチーム名を入力する。

### 11. SSH接続の実行
`warp-cli target list`コマンドで接続できるターゲットを確認してから、通常通り`ssh username@192.168.1.2`のようにsshコマンドによって接続する。IPアドレスはSSHサーバーのIPアドレスをそのまま入力する。

- 参考：
  - [SSH に VPN 箱なんてジャマ ... 2018 - 2024](https://zenn.dev/oymk/articles/67aa84d74ad263)
  - [SSH with Access for Infrastructure (recommended) · Cloudflare Zero Trust docs](https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/use-cases/ssh/ssh-infrastructure-access/)
