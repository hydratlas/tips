# 実行
## Dockerコンテナをテスト実行
```sh
docker run hello-world
```

## Docker Composeをテスト実行
```sh
cd "$HOME" &&
tee docker-compose.yml << 'EOF' >/dev/null &&
services:
  hello:
    image: hello-world
EOF
if type docker-compose >/dev/null 2>&1; then
  docker-compose up
else
  docker compose up
fi
```
