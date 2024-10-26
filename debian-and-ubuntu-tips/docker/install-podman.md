# Podman周りのインストール
## Podmanをインストール
### パッケージをインストール・確認
実行：任意のユーザー／権限：sudo可能ユーザー／対象：全ユーザー
```bash
sudo apt-get install -y podman &&
sudo apt-get install --no-install-recommends -y podman-docker &&
sudo perl -p -i -e 's/^#? ?unqualified-search-registries = .+$/unqualified-search-registries = ["docker.io"]/g' /etc/containers/registries.conf &&
sudo touch /etc/containers/nodocker &&
docker version
```

### ZFSおよびLXC上の場合の追加設定
実行：rootユーザー／権限：rootユーザー／対象：rootユーザー（sudoを含む）

ファイルシステムがZFSであり、なおかつコンテナーのLXC上でPodmanを動かす場合、不具合があるため、対応が必要。これはLXCのrootユーザー用である。
```bash
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
```bash
reboot
```
- [storage.conf mishandling with zfs storage driver · Issue #20324 · containers/podman](https://github.com/containers/podman/issues/20324)
- [Podman on LXC with ZFS backed volume and Overlay | Proxmox Support Forum](https://forum.proxmox.com/threads/podman-on-lxc-with-zfs-backed-volume-and-overlay.138722/)

## Podmanのソケットを有効化
ソケットが必要なアプリケーションを使う場合に実行する。ソケットはユーザーごとに別個であるため、使うユーザー用のソケットをおのおの有効化する。

### rootユーザー用
実行：任意のユーザー／権限：sudo可能ユーザー／対象：rootユーザー（sudoを含む）
```bash
sudo systemctl enable --now podman.socket
```

### 非rootユーザー用
実行：任意のユーザー／権限：一般ユーザー／対象：各ユーザー
```bash
systemctl --user enable --now podman.socket &&
cat << EOS >> "$HOME/.bashrc" &&

# Podman
if [ -e "$XDG_RUNTIME_DIR/podman/podman.sock" ]; then
  export DOCKER_HOST="unix://$XDG_RUNTIME_DIR/podman/podman.sock"
fi

PATH="$HOME/.local/bin:$PATH"
EOS
. "$HOME/.bashrc"
```

## Docker Composeをインストール
Docker Composeを使わない場合には必要ない。

### バイナリーをインストール・確認
実行：任意のユーザー／権限：sudo可能ユーザー／対象：全ユーザー
```bash
sudo wget -O "/usr/local/bin/docker-compose" "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" &&
sudo chmod a+x "/usr/local/bin/docker-compose" &&
docker-compose --version
```
実際に使う前に、ソケットを有効化しておく必要がある。
