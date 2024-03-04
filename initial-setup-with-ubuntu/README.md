# Ubuntuの初期設定
## キーボード配列を日本語109にする（管理者）
```
sudo perl -p -i -e "s/^XKBMODEL=.+\$/XKBMODEL=\"pc105\"/g;s/^XKBLAYOUT=.+\$/XKBLAYOUT=\"jp\"/g;s/^XKBVARIANT=.+\$/XKBVARIANT=\"OADG109A\"/g" "/etc/default/keyboard" &&
sudo dpkg-reconfigure --frontend noninteractive keyboard-configuration
```

## ロケールをシステム全体ではC.UTF-8にした上で、ユーザー個別ではja_JP.UTF-8に設定可能にする（管理者）
```
sudo apt-get install -y language-pack-ja &&
sudo locale-gen "C.UTF-8" &&
sudo locale-gen "ja_JP.UTF-8" &&
sudo localectl set-locale LANG=C.UTF-8 &&
sudo dpkg-reconfigure --frontend noninteractive locales
```

### 補足
「localectl set-locale」に代えて、/etc/default/localeに書き込んでもよい（おそらくlocalectlはこの処理のラッパーとなっている）。
```
echo "LANG=C.UTF-8" | sudo tee "/etc/default/locale" > /dev/null
cat "/etc/default/locale" # confirmation
```

## ロケールをログインしているユーザー個別でja_JP.UTF-8に設定する（ユーザー）
```
echo "export LANG=ja_JP.UTF-8" | tee -a "~/.bashrc" > /dev/null &&
source ~/.bashrc
```

## タイムゾーンをAsia/Tokyoにする（管理者）
```
sudo timedatectl set-timezone Asia/Tokyo &&
sudo dpkg-reconfigure --frontend noninteractive tzdata

timedatectl status # confirmation
```

### 補足
設定の場所は3つある。
```
echo "Asia/Tokyo" | sudo tee "/etc/timezone" > /dev/null
cat "/etc/timezone" # confirmation

sudo ln -sf "/usr/share/zoneinfo/Asia/Tokyo" "/etc/localtime"
readlink "/etc/localtime" # confirmation

echo "tzdata tzdata/Areas select Asia" | sudo debconf-set-selections &&
echo "tzdata tzdata/Zones/Asia select Tokyo" | sudo debconf-set-selections
```
このうち、「dpkg-reconfigure tzdata」の実行時に参照されているのは「/etc/localtime」だけである。そして、「timedatectl set-timezone」は「/etc/localtime」を書き換える。その上で「dpkg-reconfigure tzdata」を実行すれば、「/etc/timezone」を書き換えてくれる。

## aptの取得先にミラーを設定する
```
sudo tee "/etc/apt/sources.list" << EOS > /dev/null &&
deb mirror+file:/etc/apt/mirrors.txt $(lsb_release --short --codename) main restricted universe multiverse
deb mirror+file:/etc/apt/mirrors.txt $(lsb_release --short --codename)-updates main restricted universe multiverse
deb mirror+file:/etc/apt/mirrors.txt $(lsb_release --short --codename)-backports main restricted universe multiverse
deb http://security.ubuntu.com/ubuntu $(lsb_release --short --codename)-security main restricted universe multiverse
EOS
cat "/etc/apt/sources.list" && # confirmation
sudo tee "/etc/apt/mirrors.txt" && << EOS > /dev/null
http://ftp.udx.icscoe.jp/Linux/ubuntu/	priority:1
http://jp.archive.ubuntu.com/ubuntu/	priority:2
http://archive.ubuntu.com/ubuntu/
EOS
cat "/etc/apt/mirrors.txt" # confirmation
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
sudo docker run -d -p 8000:8000 -p 9443:9443 --name portainer --restart=always \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v portainer_data:/data portainer/portainer-ce:latest

# https://localhost:9443
```

## Cockpitをインストール（管理者）
```
sudo apt-get install -y -t mantic-backports --no-install-recommends \
  cockpit cockpit-ws cockpit-system cockpit-pcp cockpit-storaged cockpit-packagekit \
  cockpit-podman &&
sudo systemctl enable --now cockpit.socket

# http://xxx.local:9090
```
