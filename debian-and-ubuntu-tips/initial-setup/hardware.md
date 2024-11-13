# ハードウェアの初期設定（すべて管理者）
## 次回起動時にUEFI設定画面を表示する
```sh
sudo systemctl reboot --firmware-setup
```

## ノートパソコンのふたをしめてもサスペンドしないようにする
```sh
sudo perl -p -i -e 's/^#?HandleLidSwitch=.+$/HandleLidSwitch=ignore/g;' /etc/systemd/logind.conf &&
sudo systemctl restart systemd-logind.service
```

## NVMeの情報を表示
```sh
sudo apt install -yq nvme-cli &&
sudo nvme smart-log /dev/nvme0
```
