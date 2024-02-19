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
sudo apt-get install -y podman podman-docker uidmap &&
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

## Cockpitをインストール（管理者）
```
sudo apt-get install -y -t mantic-backports --no-install-recommends cockpit cockpit-ws cockpit-system cockpit-pcp cockpit-packagekit cockpit-storaged cockpit-podman &&
sudo systemctl enable --now cockpit.socket

# http://xxx.local:9090
```
