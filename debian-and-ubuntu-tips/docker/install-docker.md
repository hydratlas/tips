# Dockerのインストール
## リポジトリーの設定
```sh
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
sudo apt-get install -y ca-certificates &&
sudo install -m 0755 -d /etc/apt/keyrings &&
sudo wget -qO /etc/apt/keyrings/docker.asc "https://download.docker.com/linux/${DISTRIBUTION_NAME}/gpg" &&
sudo chmod a+r /etc/apt/keyrings/docker.asc &&
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] \
  https://download.docker.com/linux/${DISTRIBUTION_NAME} \
  $(grep -oP '(?<=^VERSION_CODENAME=).+(?=$)' /etc/os-release) stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
```

## DockerおよびDocker Composeのインストール
### パッケージをインストール
```sh
sudo apt-get update &&
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
```
- [Install Docker Engine on Ubuntu | Docker Docs](https://docs.docker.com/engine/install/ubuntu/)
- [Install Docker Engine on Debian | Docker Docs](https://docs.docker.com/engine/install/debian/)

### 確認
```sh
sudo systemctl status docker.service

sudo docker version
```

## root以外のユーザーにDockerの実行を許可（Rootful Docker）
### 許可する
#### 現在ログインしているユーザー用
```sh
if ! getent group docker >/dev/null; then
  sudo groupadd docker
fi &&
sudo usermod -aG docker "$USER" &&
newgrp docker
```

#### 現在ログインしていない任意のユーザー用
```sh
if ! getent group docker >/dev/null; then
  sudo groupadd docker
fi &&
sudo usermod -aG docker "<username>"
```

### 【元に戻す】許可を取り消す
#### 現在ログインしているユーザー用
```sh
sudo gpasswd -d "$USER" docker
```
再度ログインした後に反映される。

#### 現在ログインしていない任意のユーザー用
```sh
sudo gpasswd -d "<username>" docker
```
再度ログインした後に反映される。
