# ハードウェアの初期設定（すべて管理者）
## 次回起動時にUEFI設定画面を表示する
```bash
sudo systemctl reboot --firmware-setup
```

## GRUBの待ち時間をなくす
```bash
sudo tee -a "/etc/default/grub" <<< "GRUB_RECORDFAIL_TIMEOUT=0" > /dev/null
```

## ノートパソコンのふたをしめてもサスペンドしないようにする
```bash
sudo perl -p -i -e 's/^#?HandleLidSwitch=.+$/HandleLidSwitch=ignore/g;' /etc/systemd/logind.conf &&
sudo systemctl restart systemd-logind.service
```

## QEMUゲストエージェントをインストールする
QEMU＝仮想マシンで、仮想マシンのゲストの場合にはインストールする。
```bash
sudo apt-get install --no-install-recommends -y qemu-guest-agent
```

## NVMeの情報を表示
```bash
sudo apt install -yq nvme-cli &&
sudo nvme smart-log /dev/nvme0
```
