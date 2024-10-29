# Portainerのインストール・実行
## Portainer CE Serverのインストール・実行
PodmanとDockerの両対応。Porttainer ServerとともにPorttainer Agentがインストールされる。

### Podmanの場合
#### インストール
- 前提
  - ソケットの有効化
```sh
sudo mkdir -p /etc/containers/systemd &&
sudo tee /etc/containers/systemd/portainer.container << EOS > /dev/null &&
[Container]
Image=docker.io/portainer/portainer-ce:latest
ContainerName=portainer
AutoUpdate=registry
LogDriver=journald

PublishPort=9443:9443
Volume=/run/podman/podman.sock:/var/run/docker.sock:Z
Volume=portainer_data:/data:Z

[Service]
Restart=on-success

[Install]
WantedBy=default.target
EOS
sudo systemctl daemon-reload &&
sudo systemctl start portainer.service
```
`systemctl enable`は使えないと[podman-systemd.unit — Podman documentation](https://docs.podman.io/en/latest/markdown/podman-systemd.unit.5.html)でされている。

#### 確認
```sh
sudo systemctl status portainer.service
```

#### 停止・削除
```sh
sudo systemctl stop portainer.service &&
sudo rm /etc/containers/systemd/portainer.container &&
sudo systemctl daemon-reload
```

### Dockerの場合
#### インストール
```sh
sudo docker run \
  --detach \
  -p 9443:9443 \
  -p 8000:8000 \
  --privileged \
  --name portainer \
  --restart=always \
  --volume /var/run/docker.sock:/var/run/docker.sock:Z \
  --volume portainer_data:/data:Z \
  docker.io/portainer/portainer-ce:latest
```

#### 停止・自動再起動の無効化・削除
```sh
sudo docker stop portainer &&
sudo docker update --restart=no portainer &&
sudo docker rm portainer
```

## Rootless Portainer CEのインストール・実行
PodmanとDockerの両対応。

### Podmanの場合
#### インストール
- 前提
  - ソケットの有効化（ユーザーごとの設定）
  - linger（居残り）の有効化（ユーザーごとの設定）
```sh
mkdir -p "$HOME/.config/containers/systemd" &&
tee "$HOME/.config/containers/systemd/portainer.container" << EOS > /dev/null &&
[Container]
Image=docker.io/portainer/portainer-ce:latest
ContainerName=portainer
AutoUpdate=registry
LogDriver=journald
SecurityLabelDisable=true

PublishPort=9443:9443
Volume=${XDG_RUNTIME_DIR}/podman/podman.sock:/var/run/docker.sock:Z
Volume=portainer_data:/data:Z

[Service]
Restart=on-success

[Install]
WantedBy=default.target
EOS
systemctl --user daemon-reload &&
systemctl --user start portainer.service
```
`systemctl enable`は使えないと[podman-systemd.unit — Podman documentation](https://docs.podman.io/en/latest/markdown/podman-systemd.unit.5.html)でされている。

#### 確認
```sh
systemctl --user status portainer.service
```

#### 停止・削除
```sh
systemctl --user stop portainer.service &&
rm "$HOME/.config/containers/systemd/portainer.container" &&
systemctl --user daemon-reload
```

### Dockerの場合
#### インストール
- 前提
  - linger（居残り）の有効化（ユーザーごとの設定）
```sh
docker run \
  --detach \
  -p 9443:9443 \
  -p 8000:8000 \
  --name portainer \
  --restart=always \
  --security-opt label=disable \
  --volume "${XDG_RUNTIME_DIR}/docker.sock:/var/run/docker.sock:Z" \
  --volume portainer_data:/data:Z \
  docker.io/portainer/portainer-ce:latest
```

#### 停止・削除
```sh
docker stop portainer &&
docker rm portainer
```

## Portainer Agentのインストール・実行
PodmanとDockerの両対応。Porttainer Agentのみインストールされる。

### Podmanの場合
#### インストール
- 前提
  - ソケットの有効化
```sh
sudo mkdir -p /etc/containers/systemd &&
sudo tee /etc/containers/systemd/portainer-agent.container << EOS > /dev/null &&
[Container]
Image=docker.io/portainer/agent:latest
ContainerName=portainer-agent
AutoUpdate=registry
LogDriver=journald

PublishPort=9001:9001
Volume=/run/podman/podman.sock:/var/run/docker.sock:Z
Volume=/var/lib/containers/storage/volumes:/var/lib/docker/volumes:Z
Volume=/:/host:Z

[Service]
Restart=on-success

[Install]
WantedBy=default.target
EOS
sudo systemctl daemon-reload &&
sudo systemctl start portainer-agent.service
```

#### 確認
```sh
sudo systemctl status portainer-agent.service
```

#### 停止・削除
```sh
sudo systemctl stop portainer-agent.service &&
sudo rm /etc/containers/systemd/portainer-agent.container &&
sudo systemctl daemon-reload
```
