# lazydockerのインストール・実行
PodmanとDockerの両対応。また、Rootful DockerとRootless Dockerの両対応。

## インストール
Podmanの場合には、ソケットを有効化しておく必要がある。
```sh
wget -q -O- https://raw.githubusercontent.com/jesseduffield/lazydocker/master/scripts/install_update_linux.sh | env DIR=/usr/local/bin sudo -E bash -x
```
アップデートも同様の手順。

## 実行（root）
```sh
sudo lazydocker
```

## 実行（非root）
```sh
lazydocker
```