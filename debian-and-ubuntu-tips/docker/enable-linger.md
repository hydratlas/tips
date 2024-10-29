# linger（居残り）を有効化（各ユーザー）
非rootユーザーの場合、デフォルトではログインしているときしかサービスを起動させておけない。サービスを常時起動させられるようにするには、systemdのサービスのlinger（居残り）を有効化する。

## 有効化
```sh
sudo loginctl enable-linger "$USER"
```

## 確認
```sh
loginctl user-status "$USER" | grep Linger:

ls /var/lib/systemd/linger
```

## 【元に戻す】無効化
```sh
sudo loginctl disable-linger "$USER"
```
