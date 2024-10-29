
# DockerまたはPodmanコンテナエンジンの管理ツール
lazydockerが機能は少ないものの、独立したユーザー管理が不要で運用コストが低い。

## lazydockerのインストール・実行
実行：任意のユーザー／権限：sudo可能ユーザー／対象：全ユーザー

PodmanとDockerの両対応。また、Rootful DockerとRootless Dockerの両対応。

### インストール
Podmanの場合には、前提として、ソケットを有効化しておく必要がある。
```sh
wget -q -O- https://raw.githubusercontent.com/jesseduffield/lazydocker/master/scripts/install_update_linux.sh | env DIR=/usr/local/bin sudo -E bash -x
```
アップデートも同様の手順。

### 実行（root）
```sh
sudo lazydocker
```

### 実行（非root）
```sh
lazydocker
```

## Rootful Portainer CE Serverのインストール・実行
実行：任意のユーザー／権限：sudo可能ユーザー／対象：rootユーザー（sudoを含む）

PodmanとDockerの両対応。Porttainer ServerとともにPorttainer Agentがインストールされる。

### Podmanの場合
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

確認するとき。
```sh
sudo systemctl status portainer.service
```

停止・削除するとき。
```sh
sudo systemctl stop portainer.service &&
sudo rm /etc/containers/systemd/portainer.container &&
sudo systemctl daemon-reload
```

### Dockerの場合
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

停止・自動再起動の無効化・削除するとき。
```sh
sudo docker stop portainer &&
sudo docker update --restart=no portainer &&
sudo docker rm portainer
```

## Rootless Portainer CEのインストール・実行
実行：任意のユーザー／権限：sudo可能ユーザー／対象：各ユーザー

PodmanとDockerの両対応。

### Podmanの場合
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

確認するとき。
```sh
systemctl --user status portainer.service
```

停止・削除するとき。
```sh
systemctl --user stop portainer.service &&
rm "$HOME/.config/containers/systemd/portainer.container" &&
systemctl --user daemon-reload
```

### Dockerの場合
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

停止・削除するとき。
```sh
docker stop portainer &&
docker rm portainer
```

## Rootful Portainer Agentのインストール・実行
実行：任意のユーザー／権限：sudo可能ユーザー／対象：rootユーザー（sudoを含む）

PodmanとDockerの両対応。Porttainer Agentのみインストールされる。

### Podmanの場合
前提として、ソケットを有効化しておく必要がある。
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

確認するとき。
```sh
sudo systemctl status portainer-agent.service
```

停止・削除するとき。
```sh
sudo systemctl stop portainer-agent.service &&
sudo rm /etc/containers/systemd/portainer-agent.container &&
sudo systemctl daemon-reload
```

## Cockpit-Podmanのインストール・実行
実行：任意のユーザー／権限：sudo可能ユーザー／対象：rootユーザー（sudoを含む）

Podmanのみに対応。サーバー全体をウェブインターフェースで管理するCockpitの本体が入っていることを前提として、プラグインをインストールする。

### 通常版をインストールする場合
```sh
sudo apt-get install --no-install-recommends -y cockpit-podman
```

### バックポート版をインストールする場合
通常版よりバージョンが新しい。
```sh
sudo apt-get install --no-install-recommends -y \
  -t "$(lsb_release --short --codename)-backports" cockpit-podman
```

## Dockgeのインストール・実行
実行：任意のユーザー／権限：sudo可能ユーザー／対象：rootユーザー（sudoを含む）

ひとまずRootful Dockerのみ対応。

### インストール
```sh
sudo mkdir -p /opt/stacks /opt/dockge &&
sudo wget -O /opt/dockge/compose.yaml https://raw.githubusercontent.com/louislam/dockge/master/compose.yaml
```

### 実行（root）
```sh
cd /opt/dockge
if type docker-compose >/dev/null 2>&1; then
  sudo docker-compose up -d
else
  sudo docker compose up -d
fi
```
ポート5001にアクセスするとウェブユーザーインターフェースが表示される。
