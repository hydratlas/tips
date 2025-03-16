# Podman周りのインストール
## Podmanのインストール
### パッケージをインストール・確認
#### 最小限
```sh
sudo apt-get install -y podman &&
podman version
```

#### 【オプション】Dockerとの互換性を高める
```sh
sudo apt-get install --no-install-recommends -y podman-docker &&
sudo perl -pi -e 's/^#? ?unqualified-search-registries = .+$/unqualified-search-registries = ["docker.io"]/g' /etc/containers/registries.conf &&
sudo touch /etc/containers/nodocker &&
docker version
```

#### 【オプション】非rootユーザーのコンテナがping実行可能にする
```sh
sudo tee /etc/sysctl.d/99-ping-group-range.conf << EOS > /dev/null &&
net.ipv4.ping_group_range=0 2147483647
EOS
sudo sysctl --system &&
sysctl net.ipv4.ping_group_range
```

### ZFSおよびLXC上の場合の追加設定
ファイルシステムがZFSであり、なおかつコンテナーのLXC上でPodmanを動かす場合、不具合があるため、対応が必要。rootユーザー用である。
```sh
tee /usr/local/bin/overlayzfsmount << EOS > /dev/null &&
#!/bin/sh
exec /bin/mount -t overlay overlay "\$@"
EOS
chmod a+x /usr/local/bin/overlayzfsmount &&
tee /etc/containers/storage.conf << EOS > /dev/null
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
```

再起動して反映させる。
```sh
reboot
```
- [storage.conf mishandling with zfs storage driver · Issue #20324 · containers/podman](https://github.com/containers/podman/issues/20324)
- [Podman on LXC with ZFS backed volume and Overlay | Proxmox Support Forum](https://forum.proxmox.com/threads/podman-on-lxc-with-zfs-backed-volume-and-overlay.138722/)
- [[FIX] podman lxc is working on zfs with this fix · tteck/Proxmox · Discussion #3531](https://github.com/tteck/Proxmox/discussions/3531)

## 【オプション】Docker Composeのインストール
Docker Composeを使わない場合には必要ない。

### バイナリーをインストール・確認
```sh
sudo wget -O /usr/local/bin/docker-compose "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" &&
sudo chmod a+x /usr/local/bin/docker-compose &&
docker-compose --version
```
実際に使う前に、ソケットを有効化しておく必要がある。

### 【元に戻す】アンインストール
```sh
sudo rm /usr/local/bin/docker-compose
```

## 【オプション】Podmanのソケットを有効化（各ユーザー）
ソケットが必要なアプリケーションを使う場合に実行する。ソケットはユーザーごとに別個であるため、使うユーザー用のソケットをおのおの有効化する。

### rootユーザー用
#### 有効化
```sh
sudo systemctl enable --now podman.socket &&
if [ ! -e /var/run/docker.sock ]; then
  sudo ln -s /run/podman/podman.sock /var/run/docker.sock
fi
```

#### 【元に戻す】無効化
```sh
sudo systemctl disable --now podman.socket &&
sudo rm /run/podman/podman.sock &&
sudo unlink /var/run/docker.sock
```

### 非rootユーザー用
#### 有効化
```sh
systemctl --user enable --now podman.socket &&
TARGET_FILE="$HOME/.bashrc" &&
START_MARKER="# BEGIN Podman BLOCK" &&
END_MARKER="# END Podman BLOCK" &&
CODE_BLOCK=$(cat << EOS
if [ -e "$XDG_RUNTIME_DIR/podman/podman.sock" ]; then
  export DOCKER_HOST="unix://$XDG_RUNTIME_DIR/podman/podman.sock"
fi
EOS
) &&
if ! grep -q "$START_MARKER" "$TARGET_FILE"; then
  echo -e "$START_MARKER\n$CODE_BLOCK\n$END_MARKER" | tee -a "$TARGET_FILE" > /dev/null  
fi &&
. "$TARGET_FILE"
```

#### 【元に戻す】無効化
```sh
systemctl --user disable --now podman.socket &&
rm "$XDG_RUNTIME_DIR/podman/podman.sock" &&
TARGET_FILE="$HOME/.bashrc" &&
START_MARKER="# BEGIN Podman BLOCK" &&
END_MARKER="# END Podman BLOCK" &&
if grep -q "$START_MARKER" "$TARGET_FILE"; then
  sed -i "/$START_MARKER/,/$END_MARKER/d" "$TARGET_FILE"
fi &&
export DOCKER_HOST=""
```

## 【オプション】linger（居残り）を有効化（各ユーザー）
非rootユーザーの場合、デフォルトではログインしているときしかサービスを起動させておけない。コンテナを常時起動させられるようにするには、systemdのサービスのlinger（居残り）を有効化する。

コマンドは[enable-linger.md](enable-linger.md)を参照。

## Podman Quadlet周り
### オプションのドキュメント
`[Container]`に設定するオプションは[podman-systemd.unit — Podman documentation](https://docs.podman.io/en/latest/markdown/podman-systemd.unit.5.html)を参照。

### テストとエラーの表示
#### rootのサービス
```sh
sudo /usr/libexec/podman/quadlet -dryrun
```

#### 非rootのサービス
```sh
/usr/libexec/podman/quadlet -dryrun
```

## 実行中のコンテナを表示
### rootユーザーで実行中
```sh
sudo podman ps
```

### 現在のユーザーで実行中
```sh
podman ps
```
