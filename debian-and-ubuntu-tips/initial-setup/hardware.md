# ハードウェアの初期設定（すべて管理者）
## 次回起動時にUEFI設定画面を表示する
```sh
sudo systemctl reboot --firmware-setup
```

## GRUBの待ち時間をなくす
```sh
sudo tee -a "/etc/default/grub" <<< "GRUB_RECORDFAIL_TIMEOUT=0" > /dev/null
```

## ノートパソコンのふたをしめてもサスペンドしないようにする
```sh
sudo perl -p -i -e 's/^#?HandleLidSwitch=.+$/HandleLidSwitch=ignore/g;' /etc/systemd/logind.conf &&
sudo systemctl restart systemd-logind.service
```

## QEMUゲストエージェントをインストールする
QEMU＝仮想マシンで、仮想マシンのゲストの場合にはインストールする。
```sh
sudo apt-get install --no-install-recommends -y qemu-guest-agent
```

## NVMeの情報を表示
```sh
sudo apt install -yq nvme-cli &&
sudo nvme smart-log /dev/nvme0
```
