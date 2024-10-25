# Docker周りのインストール
## リポジトリーの設定（要sudo／マシン全体）
```bash
DISTRIBUTION_ID="$(grep -oP '(?<=^ID=).+(?=$)' /etc/os-release)" &&
DISTRIBUTION_NAME="" &&
if [ "${DISTRIBUTION_ID}" = "ubuntu" ]; then
  DISTRIBUTION_NAME="ubuntu"
elif [ "${DISTRIBUTION_ID}" = "debian" ]; then
  DISTRIBUTION_NAME="debian"
else
  echo "Error: Could not confirm that the OS is Ubuntu or Debian."
fi &&
sudo apt-get update &&
sudo apt-get install -y ca-certificates curl &&
sudo install -m 0755 -d /etc/apt/keyrings &&
sudo curl -fsSL "https://download.docker.com/linux/${DISTRIBUTION_NAME}/gpg" -o /etc/apt/keyrings/docker.asc &&
sudo chmod a+r /etc/apt/keyrings/docker.asc &&
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/${DISTRIBUTION_NAME} \
  $(. /etc/os-release && echo "${VERSION_CODENAME}") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
```

## 【選択肢1】Rootful DockerおよびDocker Composeをインストール
### パッケージをインストール（要sudo／マシン全体）
```bash
sudo apt-get update &&
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
```
- [Install Docker Engine on Ubuntu | Docker Docs](https://docs.docker.com/engine/install/ubuntu/)
- [Install Docker Engine on Debian | Docker Docs](https://docs.docker.com/engine/install/debian/)

### 特定のユーザーにDockerの実行を許可（要sudo／ユーザー別）
#### 現在ログインしているユーザーにDockerの実行を許可する場合
```bash
if ! getent group docker >/dev/null; then
  sudo groupadd docker
fi &&
sudo usermod -aG docker "$USER" &&
newgrp docker
```

#### 現在ログインしていない任意のユーザーにDockerの実行を許可する場合
```bash
sudo groupadd docker &&
sudo usermod -aG docker "<username>"
```

### 確認（ユーザー別）
```bash
docker version
```

## 【選択肢2】Rootless DockerおよびDocker Composeをインストール・実行
### docker-ce-rootless-extrasなどをインストール（要sudo／マシン全体）
```bash
sudo apt-get update &&
sudo apt-get install -y uidmap iptables docker-ce docker-ce-rootless-extras
sudo systemctl disable --now docker.service
```
- [Run the Docker daemon as a non-root user (Rootless mode) | Docker Docs](https://docs.docker.com/engine/security/rootless/)

### Rootless Dockerをインストール（ユーザー別）
```bash
dockerd-rootless-setuptool.sh install &&
cat << EOS >> "$HOME/.bashrc" &&

# Docker
if [ -e "$XDG_RUNTIME_DIR/docker.sock" ]; then
  export PATH=$HOME/bin:\$PATH
  export DOCKER_HOST="unix://$XDG_RUNTIME_DIR/docker.sock"
fi
EOS
. "$HOME/.bashrc" &&
docker version
```
- [Run the Docker daemon as a non-root user (Rootless mode) | Docker Docs](https://docs.docker.com/engine/security/rootless/)

### 【デバッグ用】Rootless Dockerをアンインストール（ユーザー別）
```bash
dockerd-rootless-setuptool.sh uninstall
```

### Docker Composeプラグインをインストール（ユーザー別）
```bash
mkdir -p "$HOME/.docker/cli-plugins" &&
wget -O "$HOME/.docker/cli-plugins/docker-compose" "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" &&
chmod a+x "$HOME/.docker/cli-plugins/docker-compose"
```
