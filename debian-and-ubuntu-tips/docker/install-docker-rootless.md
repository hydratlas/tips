# Rootless Dockerのインストール
参照：[Rootless mode | Docker Docs](https://docs.docker.com/engine/security/rootless/)

## 通常のDockerをインストール
[install-docker.md](install-docker.md)に従って、通常のDockerをインストールする。

## 必要なパッケージをインストール
```sh
if ! type slirp4netns >/dev/null 2>&1; then
  sudo apt-get install -y slirp4netns
fi &&
sudo apt-get install -y uidmap iptables docker-ce-rootless-extras
```

## 【オプション】通常のDockerを無効化
Rootless Dockerと通常のDockerは併用できるが、一方で通常のDockerを無効にすることもできる。

### 無効化
```sh
sudo systemctl disable --now docker.service docker.socket
sudo rm /var/run/docker.sock
```

### 確認
```sh
sudo systemctl status docker.service
```

### 【元に戻す】有効化
```sh
sudo systemctl enable --now docker.service docker.socket
```
`/var/run/docker.sock`は自動的に生成される。

## Rootless Dockerをインストール（各ユーザー）
### インストール
```sh
dockerd-rootless-setuptool.sh install
```

### 【元に戻す】アンインストール
```sh
dockerd-rootless-setuptool.sh uninstall
```

`DOCKER_HOST`環境変数や、linger（居残り）は別途、解除する。

データも削除する場合は次のコマンドを実行する。
```sh
rootlesskit rm -rf "$HOME/.local/share/docker"
```

## 【オプション】DOCKER_HOST環境変数を設定（各ユーザー）
一部のアプリケーションに必要。これを設定すると、コンテキストの切り替えができなくなることに注意。

### 設定
```sh
tee -a "$HOME/.bashrc" << EOS > /dev/null &&

# Docker
if [ -e "$XDG_RUNTIME_DIR/docker.sock" ]; then
  export DOCKER_HOST="unix://$XDG_RUNTIME_DIR/docker.sock"
fi
EOS
. "$HOME/.bashrc"
```

### 【元に戻す】設定を解除
`nano "$HOME/.bashrc"`から手動で削除した上で、次のコマンドを実行する（削除および実行しなくても問題はない）。
```sh
export DOCKER_HOST=""
```

## 【オプション】linger（居残り）を有効化（各ユーザー）
非rootユーザーの場合、デフォルトではログインしているときしかサービスを起動させておけない。コンテナを常時起動させられるようにするには、systemdのサービスのlinger（居残り）を有効化する。

コマンドは[enable-linger.md](enable-linger.md)を参照。

## 【オプション】Docker Composeプラグインをインストール（各ユーザー）
システムに`docker-compose-plugin`がインストールされておらず、なおかつシステム管理者にインストールしてもらえない場合にのみ必要。

### インストール
```sh
mkdir -p "$HOME/.docker/cli-plugins" &&
wget -O "$HOME/.docker/cli-plugins/docker-compose" "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" &&
chmod a+x "$HOME/.docker/cli-plugins/docker-compose"
```

### 【元に戻す】アンインストール
```sh
rm "$HOME/.docker/cli-plugins/docker-compose"
```

## Rootful Dockerに切り替える（各ユーザー）
DockerのエンドポイントはRootfulでは`unix:///var/run/docker.sock`、Rootlessでは`unix:///run/user/<uid>/docker.sock`であり、これを切り替える。

`DOCKER_HOST`環境変数が設定されていると、それが優先されて切り替えられないことに注意。また、ユーザーがdockerグループに所属していることによって、Rootful Dockerが使えるにようになっていないと、切り替えても実際には実行できない。

### 切り替え
```sh
docker context use default
```

### 確認
```sh
docker context ls
```
default（DOCKER ENDPOINTは`unix:///var/run/docker.sock`）に*マークが付いていればRootful Dockerに切り替わっている。

### 【元に戻す】Rootless Dockerに切り替える
```sh
docker context use rootless
```
