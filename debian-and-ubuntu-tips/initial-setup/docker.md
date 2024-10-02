# Docker関係
DockerのコンテナエンジンはDockerとその互換エンジンであるPodmanがある。大きな違いはないがPodmanはデフォルトでRootlessであり、Rootlessで使う場合にはスムーズである。

また、コンテナを管理するGUIツールがDockerの場合はPortainer、Podmanの場合はCockpitであるという違いもある。PortainerはDockerやKubernetesといったコンテナ環境の管理に特化したもので、Cockpitはサーバー全体の管理ができるものである。

## PodmanおよびDocker Composeをインストール・実行
### Podmanをインストール（管理者・マシン全体）
```
sudo apt-get install -y podman &&
sudo apt-get install --no-install-recommends -y podman-docker &&
sudo perl -p -i -e 's/^#? ?unqualified-search-registries = .+$/unqualified-search-registries = ["docker.io"]/g;' /etc/containers/registries.conf &&
sudo touch /etc/containers/nodocker
```

### CockpitとPodmanを連携させる（管理者・マシン全体）
Cockpitを使う場合のみ。
#### Cockpit通常版（バーションが古い）
```
sudo apt-get install --no-install-recommends -y cockpit-podman
```

#### Cockpitバックポート版（バーションが新しい）
```
sudo apt-get install --no-install-recommends -y \
  -t "$(lsb_release --short --codename)-backports" cockpit-podman
```

### Podmanをテスト実行（各ユーザー）
```
docker run hello-world
```

### Podman用にDocker Composeをインストール（各ユーザー）
Docker Composeを使わない場合には必要ない。
```
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

### Docker Composeを実行（各ユーザー）
```
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
```
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
```
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

## Rootless DockerおよびDocker Composeをインストール・実行
### uidmapをインストール（管理者・マシン全体）
```
sudo apt-get install --no-install-recommends -y uidmap
```
- [Run the Docker daemon as a non-root user (Rootless mode) | Docker Docs](https://docs.docker.com/engine/security/rootless/)

### Rootless Dockerをインストール（各ユーザー）
```
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

### Rootless Dockerをアンインストール（各ユーザー）
```
dockerd-rootless-setuptool.sh uninstall
```

### Docker Composeをインストール（各ユーザー）
```
mkdir -p "$HOME/.docker/cli-plugins" &&
wget -O "$HOME/.docker/cli-plugins/docker-compose" "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" &&
chmod a+x "$HOME/.docker/cli-plugins/docker-compose"
```

## Portainer CEをインストール（管理者・マシン全体）
Portainerは、RootfulとRootlessでインストール方法は変わらず共通である。
```
sudo docker volume create portainer_data &&
sudo docker run -d -p 8000:8000 -p 9443:9443 --name portainer --restart=always \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v portainer_data:/data portainer/portainer-ce:latest

# https://localhost:9443
```
