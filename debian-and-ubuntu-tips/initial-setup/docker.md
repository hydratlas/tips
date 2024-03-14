# Docker関係
## PodmanおよびDocker Composeをインストール・実行
### Podmanをインストール（管理者）
```
sudo apt-get install -y podman &&
sudo apt-get install --no-install-recommends -y podman-docker &&
sudo perl -p -i -e 's/^#? ?unqualified-search-registries = .+$/unqualified-search-registries = ["docker.io"]/g;' /etc/containers/registries.conf &&
sudo touch /etc/containers/nodocker
```

### CockpitとPodmanを連携させる
#### 通常版
```
sudo apt-get install --no-install-recommends -y cockpit-podman
```

#### バックポート版
```
sudo apt-get install --no-install-recommends -y \
  -t "$(lsb_release --short --codename)-backports" cockpit-podman
```

### Podmanを実行（ユーザー）
```
docker run hello-world
```

### Podman用にDocker Composeをインストール（ユーザー）
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

### Docker Composeを実行（ユーザー）
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
### DockerおよびDocker Composeをインストール（管理者）
#### Ubuntu
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

#### Debian
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
### uidmapをインストール（管理者）
```
sudo apt-get install --no-install-recommends -y uidmap
```
- [Run the Docker daemon as a non-root user (Rootless mode) | Docker Docs](https://docs.docker.com/engine/security/rootless/)

### Rootless Dockerをインストール（ユーザー）
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

### Rootless Dockerをアンインストール（ユーザー）
```
dockerd-rootless-setuptool.sh uninstall
```

### Docker Composeをインストール（ユーザー）
```
mkdir -p "$HOME/.docker/cli-plugins" &&
wget -O "$HOME/.docker/cli-plugins/docker-compose" "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" &&
chmod a+x "$HOME/.docker/cli-plugins/docker-compose"
```

## Portainer CEをインストール（管理者）
```
sudo docker volume create portainer_data &&
sudo docker run -d -p 8000:8000 -p 9443:9443 --name portainer --restart=always \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v portainer_data:/data portainer/portainer-ce:latest

# https://localhost:9443
```
