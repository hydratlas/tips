# ハードウェアの初期設定
## 次回起動時にUEFI設定画面を表示する（管理者）
```bash
sudo systemctl reboot --firmware-setup
```

## GRUBの待ち時間をなくす（管理者）
```bash
sudo tee -a "/etc/default/grub" <<< "GRUB_RECORDFAIL_TIMEOUT=0" > /dev/null
```

## ノートパソコンのふたをしめてもサスペンドしないようにする（管理者）
```bash
sudo perl -p -i -e 's/^#?HandleLidSwitch=.+$/HandleLidSwitch=ignore/g;' /etc/systemd/logind.conf &&
sudo systemctl restart systemd-logind.service
```

## QEMUゲストエージェントをインストールする（管理者）
QEMU＝仮想マシンで、仮想マシンのゲストの場合にはインストールする。
```bash
sudo apt-get install --no-install-recommends -y qemu-guest-agent
```

## NVMeの情報を表示
```bash
sudo apt install -yq nvme-cli &&
sudo nvme smart-log /dev/nvme0
```
