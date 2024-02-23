# Ubuntuの初期設定
## 日本時間化・日本語化（管理者）
```
sudo timedatectl set-timezone Asia/Tokyo &&
sudo apt-get install -y language-pack-ja &&
sudo localectl set-locale LANG=ja_JP.UTF-8 LANGUAGE="ja_JP:ja" &&
source /etc/default/locale
```

## PodmanおよびDocker Composeをインストール・実行
### Podmanをインストール（管理者）
```
sudo apt-get install -y podman &&
sudo apt-get install -y --no-install-recommends podman-docker &&
sudo perl -p -i -e 's/^#? ?unqualified-search-registries = .+$/unqualified-search-registries = ["docker.io"]/g;' /etc/containers/registries.conf &&
sudo touch /etc/containers/nodocker
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
```
sudo apt-get update &&
sudo apt-get install -y ca-certificates curl gnupg &&
sudo install -m 0755 -d /etc/apt/keyrings &&
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor --yes -o /etc/apt/keyrings/docker.gpg &&
sudo chmod a+r /etc/apt/keyrings/docker.gpg &&
echo \
  "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null &&
sudo apt-get update &&
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
```

- [Install Docker Engine on Ubuntu | Docker Docs](https://docs.docker.com/engine/install/ubuntu/)

## Rootless DockerおよびDocker Composeをインストール・実行
### uidmapをインストール（管理者）
```
sudo apt-get install -y uidmap
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
sudo docker run -d -p 8000:8000 -p 9443:9443 --name portainer --restart=always -v /var/run/docker.sock:/var/run/docker.sock -v portainer_data:/data portainer/portainer-ce:latest

# https://localhost:9443
```

## Cockpitをインストール（管理者）
```
sudo apt-get install -y -t mantic-backports --no-install-recommends cockpit cockpit-ws cockpit-system cockpit-pcp cockpit-packagekit cockpit-storaged cockpit-podman &&
sudo systemctl enable --now cockpit.socket

# http://xxx.local:9090
```
