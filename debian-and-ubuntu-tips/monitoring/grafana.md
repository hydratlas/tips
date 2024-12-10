# Grafana
## インストール
```sh
host_dir="/var/lib/grafana" &&
container_dir="/var/lib/grafana" &&
env_file="/etc/containers/systemd/grafana.env" &&
quadlet_file="/etc/containers/systemd/grafana.container" &&
user="admin" &&
password="$(tr -dc 'A-Za-z0-9' < /dev/urandom | head -c 24)" &&
sudo mkdir -p "$(dirname "${env_file}")" &&
sudo tee "${env_file}" << EOS > /dev/null &&
GF_SECURITY_ADMIN_USER=${user}
GF_SECURITY_ADMIN_PASSWORD=${password}
GF_USERS_ALLOW_SIGN_UP=false
GF_USERS_ALLOW_ORG_CREATE=false
EOS
sudo chmod 600 "${env_file}" &&
sudo mkdir -p "$(dirname "${quadlet_file}")" &&
sudo tee "${quadlet_file}" << EOS > /dev/null &&
[Unit]
Requires=victoria-metrics.service
Requires=loki.service
After=victoria-metrics.service
After=loki.service

[Container]
Image=docker.io/grafana/grafana-oss:latest
ContainerName=grafana
Network=monitoring.network
EnvironmentFile=${env_file}
AutoUpdate=registry
LogDriver=journald

PublishPort=3000:3000
Volume=${host_dir}:${container_dir}:Z
Volume=/etc/localtime:/etc/localtime:ro
User=0

[Service]
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOS
sudo mkdir -p "${host_dir}" &&
sudo systemctl daemon-reload &&
sudo systemctl start grafana.service &&
sudo cat "${env_file}"
```
- 参考：
  - [Run Grafana Docker image | Grafana documentation](https://grafana.com/docs/grafana/latest/setup-grafana/installation/docker/)

## 確認
```sh
sudo systemctl status grafana.service
```

## 初期設定
- [http://example.com:3000]()にアクセス
  - `example.com`はインストールしたマシン（Podmanのホスト）に応じて書き換える
- `GF_SECURITY_ADMIN_USER`で設定しているユーザー名と、`GF_SECURITY_ADMIN_PASSWORD`で設定しているパスワードを入力してログイン
- 左ペイン「Connections」内の「Data sources」画面で、右上の「Add new data source」ボタンを押す
  - Prometheusのデータソースを追加
    - URLは`http://victoria-metrics:8428/`
  - Lokiのデータソースを追加
    - URLは`http://loki:3100/`
  - 「Save & Test」ボタンを押して登録する
- 左ペインの「Dashboards」画面で、右上の`New`ボタンから`Import`を選択する
  - IDとして`1860`を入力して、`Load`を押す。データソースはPrometheusを使用する
    - [Node Exporter Full | Grafana Labs](https://grafana.com/ja/grafana/dashboards/1860-node-exporter-full/)
  - IDとして`14055`を入力して、`Load`を押す。データソースはPrometheusおよびLokiを使用する
    - [Loki stack monitoring (Promtail, Loki) | Grafana Labs](https://grafana.com/grafana/dashboards/14055-loki-stack-monitoring-promtail-loki/)

## 【デバッグ用】再起動
```sh
sudo systemctl restart grafana.service
```

## 【デバッグ用】停止・削除
```sh
sudo systemctl stop grafana.service &&
sudo rm /etc/containers/systemd/grafana.container &&
sudo systemctl daemon-reload &&
sudo rm -dr /var/lib/grafana
```
