# Dockgeのインストール・実行
## インストール
```sh
sudo mkdir -p /opt/stacks /opt/dockge &&
sudo wget -O /opt/dockge/compose.yaml https://raw.githubusercontent.com/louislam/dockge/master/compose.yaml
```

## 実行（root限定）
```sh
cd /opt/dockge
if type docker-compose >/dev/null 2>&1; then
  sudo docker-compose up -d
else
  sudo docker compose up -d
fi
```
ポート5001にアクセスするとウェブユーザーインターフェースが表示される。
