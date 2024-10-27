# Docker周りのインストール
## リポジトリーの設定
実行：任意のユーザー／権限：sudo可能ユーザー／対象：rootユーザー（sudoを含む）
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

## Rootful DockerおよびDocker Composeをインストール
実行：任意のユーザー／権限：sudo可能ユーザー／対象：特定のユーザー

### パッケージをインストール（対象：全ユーザー）
```bash
sudo apt-get update &&
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
```
- [Install Docker Engine on Ubuntu | Docker Docs](https://docs.docker.com/engine/install/ubuntu/)
- [Install Docker Engine on Debian | Docker Docs](https://docs.docker.com/engine/install/debian/)

### Dockerの実行を許可（対象：特定のユーザー）
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

### 確認
```bash
docker version
```

## Rootless DockerおよびDocker Composeをインストール・実行
実行：任意のユーザー／権限：sudo可能ユーザー／対象：各ユーザー

### 最低限のRootful Dockerをインストール（対象：全ユーザー）
システムでもDockerを使うことは多いが、その場合は最低限ではない通常のRootful Dockerをインストールして構わない。最低限といっても、実際には`docker-ce`に設定されている依存関係により`docker-ce-cli`、`containerd.io`、`docker-buildx-plugin`および`docker-compose-plugin`が同時にインストールされる模様。
```bash
sudo apt-get update &&
sudo apt-get install -y docker-ce
```

### 【オプション】Rootful Dockerを無効化（対象：全ユーザー）
Rootless DockerとRootful Dockerは併用できるが、一方でRootful Dockerを無効にすることもできる。
```bash
sudo systemctl disable --now docker.service docker.socket
sudo rm /var/run/docker.sock
```

### 【オプション】Rootful Dockerを有効化（対象：全ユーザー）
再度、Rootful Dockerを有効にすることもできる。`/var/run/docker.sock`は自動的に生成される。
```bash
sudo systemctl enable --now docker.service docker.socket
```

### docker-ce-rootless-extrasなどをインストール（対象：全ユーザー）
```bash
sudo apt-get install -y uidmap iptables docker-ce-rootless-extras
```
参照：[Rootless mode | Docker Docs](https://docs.docker.com/engine/security/rootless/)

### Rootless Dockerをインストール（対象：各ユーザー）
```bash
dockerd-rootless-setuptool.sh install &&
docker version &&
cat << EOS >> "$HOME/.bashrc" &&

# Docker
if [ -e "$XDG_RUNTIME_DIR/docker.sock" ]; then
  export PATH=$HOME/bin:\$PATH
  export DOCKER_HOST="unix://$XDG_RUNTIME_DIR/docker.sock"
fi
EOS
. "$HOME/.bashrc"
```

### 非rootユーザーのlinger（居残り）を有効化（対象：各ユーザー）
実行：任意のユーザー／権限：sudo可能ユーザー／対象：各ユーザー

非rootユーザーの場合、デフォルトではログインしているときしかコンテナを起動させておけない。コンテナを常時起動させられるようにするには、systemdのlinger（居残り）を有効化する。
```bash
sudo loginctl enable-linger "$USER"
```

### 【デバッグ用】Rootless Dockerをアンインストール（対象：各ユーザー）
```bash
dockerd-rootless-setuptool.sh uninstall
```

### 【オプション】Docker Composeプラグインをインストール（対象：各ユーザー）
Rootful Docker側で`docker-compose-plugin`をインストールしている場合は不要。
```bash
mkdir -p "$HOME/.docker/cli-plugins" &&
wget -O "$HOME/.docker/cli-plugins/docker-compose" "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" &&
chmod a+x "$HOME/.docker/cli-plugins/docker-compose"
```
