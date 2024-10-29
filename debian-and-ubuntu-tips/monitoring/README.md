# 監視
Node Exporter + VictoriaMetrics (Single version) + Grafanaという構成で、サーバーのCPU使用率をはじめとしたシステムパフォーマンスを監視する。

- Node Exporter: 監視対象の各マシンにおいて、システムパフォーマンスを測定してHTTPで公開する
- VictoriaMetrics (Single version): Node ExporterからHTTPで測定データを収集して、集積する
- Grafana: VictoriaMetricsにHTTPでアクセスして、グラフ化などによって分かりやすく視覚化する

ここでは、監視対象の各マシンにはDockerが入らない可能性があるため、Node Exporterは手動でバイナリーをインストールする。VictoriaMetricsおよびGrafanaはDocker(Podman)でインストールする。

## Node Exporter
監視対象のそれぞれのマシンにインストールする。[node-exporter.md](debian-and-ubuntu-tips/monitoring/node-exporter.md)を参照。

## VictoriaMetrics (Single version)およびGrafana
1台のマシンにインストールする。Podman Quadletを使用しているため、Podman 4.6以上のインストールが必要。Ubuntu LTSなら24.04以上。

### VictoriaMetrics (Single version)
#### インストール
```bash
sudo mkdir -p /etc/prometheus &&
sudo touch /etc/prometheus/prometheus.yml &&
sudo mkdir -p /var/lib/victoria-metrics-data &&
sudo mkdir -p /etc/containers/systemd &&
sudo tee /etc/containers/systemd/monitoring.network  << EOS > /dev/null &&
[Unit]
Description=Monitoring Container Network

[Network]
Label=app=monitoring
EOS
sudo tee /etc/containers/systemd/victoria-metrics.container << EOS > /dev/null &&
[Container]
Image=docker.io/victoriametrics/victoria-metrics
ContainerName=victoria-metrics
Network=monitoring.network
AutoUpdate=registry
LogDriver=journald

Volume=/var/lib/victoria-metrics-data:/victoria-metrics-data:Z
Volume=/etc/prometheus/prometheus.yml:/etc/prometheus/prometheus.yml:Z
Exec='-promscrape.config=/etc/prometheus/prometheus.yml'

[Service]
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOS
sudo systemctl daemon-reload &&
sudo systemctl start victoria-metrics.service
```
- 参考：
  - [VictoriaMetrics](https://docs.victoriametrics.com/)
  - [VictoriaMetrics/package/victoria-metrics.service at master · VictoriaMetrics/VictoriaMetrics](https://github.com/VictoriaMetrics/VictoriaMetrics/blob/master/package/victoria-metrics.service)

`/etc/prometheus/prometheus.yml`の中身の例。
```yaml
scrape_configs:
  - job_name: node
    static_configs:
      - targets:
        - 192.168.0.xxx:9100:label1
        - 192.168.0.xxx:9100:label2
    relabel_configs:
      - source_labels: [__address__]
        regex: '([^:]+):(\d+):([^:]+)'
        target_label: instance
        replacement: '${3}:${2}'
      - source_labels: [__address__]
        regex: '([^:]+):(\d+):([^:]+)'
        target_label: __address__
        replacement: '${1}:${2}'
```
参考：[Prometheusでinstance名をホスト名にしたい #prometheus - Qiita](https://qiita.com/fkshom/items/bafb2160e2c9ca8ded38)

#### 確認
```bash
sudo systemctl status victoria-metrics.service
```

#### 【デバッグ用】再起動
```bash
sudo systemctl restart victoria-metrics.service
```

#### 【デバッグ用】停止・削除
```bash
sudo systemctl stop victoria-metrics.service &&
sudo rm /etc/containers/systemd/victoria-metrics.container &&
sudo systemctl daemon-reload
```


### Grafana
#### インストール
```bash
sudo mkdir -p /var/lib/grafana &&
sudo mkdir -p /etc/containers/systemd &&
sudo tee /etc/containers/systemd/grafana.container << EOS > /dev/null &&
[Unit]
Requires=victoria-metrics.service
After=victoria-metrics.service

[Container]
Image=docker.io/grafana/grafana-oss
ContainerName=grafana
Network=monitoring.network
AutoUpdate=registry
LogDriver=journald

PublishPort=3000:3000
Volume=/var/lib/grafana:/var/lib/grafana:Z
User=0

[Service]
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOS
sudo systemctl daemon-reload &&
sudo systemctl start grafana.service
```
- 参考：
  - [Run Grafana Docker image | Grafana documentation](https://grafana.com/docs/grafana/latest/setup-grafana/installation/docker/)

#### 確認
```bash
sudo systemctl status grafana.service
```

#### 初期設定
- [http://example.com:3000]()にアクセス。`example.com`はインストールしたマシン（Podmanのホスト）に応じて書き換える。
- デフォルトのユーザー名とパスワードの`admin`を入力してログイン
- 新しいパスワードの設定を求められるため設定
- Data sources画面で、右上の`Add new data source`からPrometheusのデータソースを追加
  - URLは`http://victoria-metrics:8428/`
- Dashboards画面で、右上の`New`から`Import`を選択し、IDとしてNode Exporter用の`1860`を入力してから`Load`を押す
  - [Node Exporter Full | Grafana Labs](https://grafana.com/ja/grafana/dashboards/1860-node-exporter-full/)

#### 【デバッグ用】再起動
```bash
sudo systemctl restart grafana.service
```

#### 【デバッグ用】停止・削除
```bash
sudo systemctl stop grafana.service &&
sudo rm /etc/containers/systemd/grafana.container &&
sudo systemctl daemon-reload
```
