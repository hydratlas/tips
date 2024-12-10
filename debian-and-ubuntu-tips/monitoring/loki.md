# Grafana Loki
## 設定・インストール
```sh
host_conf_file="/etc/loki/loki.yaml" &&
container_conf_file="/loki.yaml" &&
host_dir="/var/lib/loki" &&
container_dir="/loki" &&
quadlet_file="/etc/containers/systemd/loki.container" &&
sudo mkdir -p "$(dirname "${host_conf_file}")" &&
sudo tee "${host_conf_file}" << EOS > /dev/null &&
auth_enabled: false

server:
  http_listen_port: 3100

common:
  instance_addr: 127.0.0.1
  path_prefix: ${container_dir}
  storage:
    filesystem:
      chunks_directory: ${container_dir}/chunks
      rules_directory: ${container_dir}/rules
  replication_factor: 1
  ring:
    kvstore:
      store: inmemory

schema_config:
  configs:
    - from: 2020-10-24
      store: tsdb
      object_store: filesystem
      schema: v13
      index:
        prefix: index_
        period: 24h

ruler:
  alertmanager_url: http://localhost:9093

# By default, Loki will send anonymous, but uniquely-identifiable usage and configuration
# analytics to Grafana Labs. These statistics are sent to https://stats.grafana.org/
#
# Statistics help us better understand how Loki is used, and they show us performance
# levels for most users. This helps us prioritize features and documentation.
# For more information on what's sent, look at
# https://github.com/grafana/loki/blob/main/pkg/usagestats/stats.go
# Refer to the buildReport method to see what goes into a report.
#
# If you would like to disable reporting, uncomment the following lines:
#analytics:
#  reporting_enabled: false
EOS
sudo mkdir -p "${host_dir}" &&
sudo mkdir -p "$(dirname "${quadlet_file}")" &&
sudo tee "${quadlet_file}" << EOS > /dev/null &&
[Container]
Image=docker.io/grafana/loki:latest
ContainerName=loki
Network=monitoring.network
AutoUpdate=registry
LogDriver=journald

PublishPort=3100:3100
Volume=${host_conf_file}:${container_conf_file}:z
Volume=${host_dir}:${container_dir}:Z
User=0
Exec=-config.file=${container_conf_file}

[Service]
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOS
sudo systemctl daemon-reload &&
sudo systemctl start loki.service
```
- [https://github.com/grafana/loki/blob/main/cmd/loki/loki-docker-config.yaml]()

## 確認
```sh
sudo systemctl status loki.service
```

## 【デバッグ用】再起動
```sh
sudo systemctl restart loki.service
```

## 【デバッグ用】停止・削除
```sh
sudo systemctl stop loki.service &&
sudo rm /etc/containers/systemd/loki.container &&
sudo systemctl daemon-reload
```
