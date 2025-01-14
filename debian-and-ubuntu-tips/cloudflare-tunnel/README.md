# Cloudflare Tunnel
[Create a remotely-managed tunnel (dashboard) · Cloudflare Zero Trust docs](https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/get-started/create-remote-tunnel/)

## Cloudflareダッシュボードによる設定
「Zero Trust」→「Networks」→「Tunnels」から、トンネルを作成する。dockerコマンドによるインストール方法を表示して、トークンを取得する。

## インストール・サービスの起動
`token`変数は適宜書き換える。
```sh
token="abc" &&
container_user="cloudflared" &&
sudo apt-get install -y podman &&
if ! id "${container_user}" &>/dev/null; then
    sudo useradd --system --no-create-home --user-group "${container_user}"
fi &&
sudo install -m 750 -o "root" -g "${container_user}" /dev/stdin "/usr/local/etc/cloudflared.env" << EOS > /dev/null &&
TUNNEL_TOKEN=${token}
NO_AUTOUPDATE=true
EOS
sudo tee "/etc/containers/systemd/cloudflared.container" << EOS > /dev/null &&
[Container]
Image=docker.io/cloudflare/cloudflared:latest
ContainerName=cloudflared
AutoUpdate=registry
LogDriver=journald
User=$(id -u "${container_user}")
Group=$(id -g "${container_user}")
EnvironmentFile=/usr/local/etc/cloudflared.env

Exec=tunnel --no-autoupdate run

[Service]
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOS
sudo systemctl daemon-reload &&
sudo systemctl start cloudflared.service &&
sudo systemctl status --no-pager --full cloudflared.service
```

## 【元に戻す】停止・削除
```sh
sudo systemctl stop cloudflared.service &&
sudo rm /etc/containers/systemd/cloudflared.container &&
sudo systemctl daemon-reload &&
sudo rm "/usr/local/etc/cloudflared.env"
```

## Cloudflareダッシュボードによる設定
### HTTPS
「Zero Trust」→「Networks」→「Tunnels」から、トンネルの設定画面を表示する。上部に「Overview」、「Public Hostname」および「Private Network」という3つのタブが表示されるため、「Public Hostname」を選択する。

追加ボタンを押し「Subdomain」、「Domain」および「Path」に外部に公開するURLを指定する。このとき「Path」は内部のアクセス先にも影響する（内部のアクセス先のパスを限定する機能がある）ため注意。また、「Type」および「URL」に内部のアクセス先を指定する。

HTTPSの場合にはTLS設定として「No TLS Verify」が選べる。内部ではTLSの証明書を設定しない場合も多いが、その場合はオンにする。

### SSH
「Zero Trust」→「Networks」→「Tunnels」から、トンネルの設定画面を表示する。上部に「Overview」、「Public Hostname」および「Private Network」という3つのタブが表示されるため、「Private Network」を選択する。

追加ボタンを押し「CIDR」にSSHサーバーのIPアドレスと「/32」を入力して（例：192.168.1.2/32）、保存する。

「Zero Trust」→「Settings」→「WARP Client」から、「Device enrollment permissions」の「Manage」ボタンを押す。「Device enrollment permissions」画面が表示されるので、「Add a rule」ボタンを押し、任意の名前と「Selector」は「Country」、「Value」は「Japan」と入力して、保存する。

「Zero Trust」→「Settings」→「WARP Client」から、「Device settings」の中の「Default」の設定を変更する。「Split Tunnels」の「Manage」ボタンを押す。除外されているIPアドレスの一覧が出てくるので、SSHサーバーのIPアドレスが含まれるものを削除する。この削除操作は保存は明示的にする必要がない。

「Zero Trust」→「Settings」→「Custom Pages」から、表示されるチーム名（*.cloudflareaccess.com）を控える。

クライアントにWARPをインストールする。ダウンロード先はGUIの場合は[Download WARP · Cloudflare Zero Trust docs](https://developers.cloudflare.com/cloudflare-one/connections/connect-devices/warp/download-warp/)、CUIの場合は[Cloudflare WARP packages](https://pkg.cloudflareclient.com/)である。

インストールしたら、「設定」→「アカウント」からZero Trustに接続する。その際、控えておいたチーム名を入力する。

参考：[Cloudflare Zero Trustを利用して外部ネットワークから自宅サーバにSSHする #cloudflare - Qiita](https://qiita.com/sey323/items/c9d43f2c930b8602c46c)
