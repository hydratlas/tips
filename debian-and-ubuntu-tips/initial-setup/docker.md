# Docker関係
DockerのコンテナエンジンはDockerとその互換エンジンであるPodmanがある。大きな違いはないがPodmanはデフォルトでRootlessであり、Rootlessで使う場合にはスムーズである。

また、コンテナを管理するGUIツールがDockerの場合はPortainer、Podmanの場合はPortainerまたはCockpitであるという違いもある。PortainerはDockerやKubernetesといったコンテナ環境の管理に特化したもので、Cockpitはサーバー全体の管理ができるものである。

## PodmanおよびDocker Composeをインストール・実行
### Podmanをインストール（管理者・マシン全体）
#### Podman本体をインストール
```bash
sudo apt-get install -y podman &&
sudo apt-get install --no-install-recommends -y podman-docker &&
sudo perl -p -i -e 's/^#? ?unqualified-search-registries = .+$/unqualified-search-registries = ["docker.io"]/g;' /etc/containers/registries.conf &&
sudo touch /etc/containers/nodocker
```

#### ZFSおよびLXC上でPodmanを設定
ファイルシステムがZFSであり、なおかつコンテナーのLXC上でPodmanを動かす場合、不具合があるため、対応が必要。
```bash
sed -i 's/^#? ?unqualified-search-registries = .+$/unqualified-search-registries = ["docker.io"]/g;' /etc/containers/registries.conf &&
touch /etc/containers/nodocker &&
tee /usr/local/bin/overlayzfsmount << EOS > /dev/null &&
#!/bin/sh
exec /bin/mount -t overlay overlay "\$@"
EOS
chmod a+x /usr/local/bin/overlayzfsmount &&
tee /etc/containers/storage.conf << EOS > /dev/null &&
[storage]
driver = "overlay"
runroot = "/run/containers/storage"
graphroot = "/var/lib/containers/storage"

[storage.options]
pull_options = {enable_partial_images = "false", use_hard_links = "false", ostree_repos=""}
mount_program = "/usr/local/bin/overlayzfsmount"

[storage.options.overlay]
mountopt = "nodev"
EOS
reboot
```
- [storage.conf mishandling with zfs storage driver · Issue #20324 · containers/podman](https://github.com/containers/podman/issues/20324)
- [Podman on LXC with ZFS backed volume and Overlay | Proxmox Support Forum](https://forum.proxmox.com/threads/podman-on-lxc-with-zfs-backed-volume-and-overlay.138722/)

#### Podmanをテスト実行（各ユーザー）
```bash
docker run hello-world
```

### CockpitでPodmanコンテナを管理する（管理者・マシン全体）
Cockpitを使う場合のみ。
#### Cockpit通常版をインストール（バーションが古い）
```bash
sudo apt-get install --no-install-recommends -y cockpit-podman
```

#### Cockpitバックポート版をインストール（バーションが新しい）
```bash
sudo apt-get install --no-install-recommends -y \
  -t "$(lsb_release --short --codename)-backports" cockpit-podman
```

### Portainer CEでPodmanコンテナを管理する（各ユーザー）
#### Portainer CEをインストール
```bash
docker volume create portainer_data &&
docker run -d -p 8000:8000 -p 9443:9443 --name portainer --restart=always \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v portainer_data:/data portainer/portainer-ce:latest

# https://localhost:9443
```

#### Portainer Agentをインストール
```bash
docker run -d \
  -p 9001:9001 \
  --name portainer_agent \
  --restart=always \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v /var/lib/containers/storage/volumes:/var/lib/docker/volumes \
  portainer/agent
```

### DockgeでPodmanコンテナを管理する（管理者・マシン全体）
```bash
sudo mkdir -p /opt/stacks /opt/dockge
cd /opt/dockge

sudo curl https://raw.githubusercontent.com/louislam/dockge/master/compose.yaml --output compose.yaml

if type docker-compose >/dev/null 2>&1; then
  sudo docker-compose up -d
else
  sudo docker compose up -d
fi
```

### Docker Composeをインストール（各ユーザー）
#### Docker Composeをインストール
Docker Composeを使わない場合には必要ない。
```bash
mkdir -p "$HOME/.local/bin" &&
wget -O "$HOME/.local/bin/docker-compose" "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" &&
chmod a+x "$HOME/.local/bin/docker-compose" &&
systemctl --user daemon-reload &&
systemctl --user enable --now podman.socket &&
cat << EOS >> "$HOME/.bashrc" &&

# Podman
if [ -e "$XDG_RUNTIME_DIR/podman/podman.sock" ]; then
  export DOCKER_HOST="unix://$XDG_RUNTIME_DIR/podman/podman.sock"
fi

PATH="$HOME/.local/bin:$PATH"
EOS
. "$HOME/.bashrc"

docker-compose --version
```

#### Docker Composeを実行
```bash
cd "$HOME" &&
tee docker-compose.yml << 'EOF' >/dev/null &&
version: "3"
services:
  hello:
    image: hello-world
EOF
docker-compose up
```

## DockerおよびDocker Composeをインストール・実行
Dockerの場合には、RootfulとRootlessでインストール方法が分かれる。

### Rootful DockerおよびDocker Composeをインストール（管理者・マシン全体）
#### Ubuntuの場合
```bash
sudo apt-get update &&
sudo apt-get install --no-install-recommends -y ca-certificates curl gnupg &&
sudo install -m 0755 -d /etc/apt/keyrings &&
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc &&
sudo chmod a+r /etc/apt/keyrings/docker.gpg &&
echo \
  "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null &&
sudo apt-get update &&
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
```
- [Install Docker Engine on Ubuntu | Docker Docs](https://docs.docker.com/engine/install/ubuntu/)

#### Debianの場合
```bash
sudo apt-get update &&
sudo apt-get install --no-install-recommends -y ca-certificates curl &&
sudo install -m 0755 -d /etc/apt/keyrings &&
sudo curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc &&
sudo chmod a+r /etc/apt/keyrings/docker.asc &&
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null &&
sudo apt-get update &&
sudo apt-get install --no-install-recommends -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

```
- [Install Docker Engine on Debian | Docker Docs](https://docs.docker.com/engine/install/debian/)

### Rootless DockerおよびDocker Composeをインストール・実行
#### uidmapをインストール（管理者・マシン全体）
```bash
sudo apt-get install --no-install-recommends -y uidmap
```
- [Run the Docker daemon as a non-root user (Rootless mode) | Docker Docs](https://docs.docker.com/engine/security/rootless/)

#### Rootless Dockerをインストール（各ユーザー）
```bash
dockerd-rootless-setuptool.sh install &&
cat << EOS >> "$HOME/.bashrc"

# Docker
if [ -e "$XDG_RUNTIME_DIR/docker.sock" ]; then
  export PATH=$HOME/bin:\$PATH
  export DOCKER_HOST="unix://$XDG_RUNTIME_DIR/docker.sock"
fi
EOS
```
- [Run the Docker daemon as a non-root user (Rootless mode) | Docker Docs](https://docs.docker.com/engine/security/rootless/)

#### Rootless Dockerをアンインストール（各ユーザー）
```bash
dockerd-rootless-setuptool.sh uninstall
```

#### Docker Composeをインストール（各ユーザー）
```bash
mkdir -p "$HOME/.docker/cli-plugins" &&
wget -O "$HOME/.docker/cli-plugins/docker-compose" "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" &&
chmod a+x "$HOME/.docker/cli-plugins/docker-compose"
```

### Portainer CEをインストール（管理者・マシン全体）
Portainerは、RootfulとRootlessでインストール方法は変わらず共通である。
```bash
sudo docker volume create portainer_data &&
sudo docker run -d -p 8000:8000 -p 9443:9443 --name portainer --restart=always \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v portainer_data:/data portainer/portainer-ce:latest

# https://localhost:9443
```
