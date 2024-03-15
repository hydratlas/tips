# Ubuntu Server 23.10をBtrfs (RAID 1)でセットアップ
## ストレージをフォーマット
### GNU GRUB画面
![](server/01_grub.png)
Try or Install Ubuntu Serverにフォーカスを当てて、Enterキーを押下する。

### Welcome!画面
![](server/02_welcome.png)
Englishにフォーカスを当てて、Enterキーを押下する。

### Keyboard configuration画面
![](server/03_keyboard_configuration.png)
Layout、VariantともにJapaneseを選択したうえで、Doneにフォーカスを当ててEnterキーを押下する。

### Choose type of install画面
![](server/04_choose_type_of_install.png)
なにもせずに、Ctrl + Alt + F2キーを押下して、コンソール画面に入る。

### コンソール画面
以下のようにスクリプトによってインストール先のストレージ2台をフォーマットする。

まず、スクリプトをダウンロードして、そのディレクトリーに移動する。
```
sudo apt install git
git clone --depth=1 https://github.com/hydratlas/tips
cd tips/debian-and-ubuntu-tips/install-ubuntu-with-btrfs
```

lsblkコマンドでインストール先のストレージの名前（sdX）を確認する。
```
lsblk -f -e 7
```

インストール先のストレージを、スクリプトによってフォーマットする。
```
sudo bash -x btrfs1.sh sdX
sudo bash -x btrfs1.sh sdX
```

最後に再起動する。
```
sudo reboot
```

## インストール
### GNU GRUB画面
![](server/01_grub.png)
Try or Install Ubuntu Serverにフォーカスを当てて、Enterキーを押下する。

### Welcome!画面
![](server/02_welcome.png)
Englishにフォーカスを当てて、Enterキーを押下する。

### Keyboard configuration画面
![](server/03_keyboard_configuration.png)
Layout、VariantともにJapaneseを選択したうえで、Doneにフォーカスを当ててEnterキーを押下する。

### Choose type of install画面
![](server/04_choose_type_of_install.png)
Ubuntu Serverを選択したうえで、Doneにフォーカスを当ててEnterキーを押下する。

### Network connections画面
![](server/05_network_connections.png)
自動的にDHCPによってIPアドレスが取得されるため、それを少し待ってからDoneにフォーカスを当ててEnterキーを押下する。

### Configure proxy画面
![](server/06_configure_proxy.png)
なにもせずに、Doneにフォーカスを当ててEnterキーを押下する。

### Configure Ubuntu archive mirror画面
![](server/07_configure_ubuntu_archive_mirror.png)
自動的にミラーが取得されるため、それを少し待ってからDoneにフォーカスを当ててEnterキーを押下する。

### Guided storage configuration画面
![](server/08_guided_storage_configuration.png)
Custom storage layoutを選択したうえで、Doneにフォーカスを当ててEnterキーを押下する。

### Storage configuration画面
![](server/09_storage_configuration.png)
1台目のストレージにフォーカスを当ててEnterキーを押下すると、サブメニューが表示される。その中からUse As Boot Deviceにフォーカスを当ててEnterキーを押下する。

![](server/10_storage_configuration.png)
2台目のストレージにフォーカスを当ててEnterキーを押下すると、サブメニューが表示される。その中からAdd As Another Boot Deviceにフォーカスを当ててEnterキーを押下する。

![](server/11_storage_configuration.png)
1台目のストレージのpartition 2にフォーカスを当ててEnterキーを押下すると、「Editing partition 2」というポップアップウィンドウが表示される。「Use as swap」にチェックを入れたうえで、Saveにフォーカスを当ててEnterキーを押下する。

![](server/12_storage_configuration.png)
2台目のストレージのpartition 2にフォーカスを当ててEnterキーを押下すると、「Editing partition 2」というポップアップウィンドウが表示される。「Use as swap」にチェックを入れたうえで、Saveにフォーカスを当ててEnterキーを押下する。

![](server/13_storage_configuration.png)
1台目のストレージのpartition 3にフォーカスを当ててEnterキーを押下すると、「Editing partition 3」というポップアップウィンドウが表示される。「Fremat」は「Btrfs」、「Mount」は「/」を選択したうえで、Saveにフォーカスを当ててEnterキーを押下する。

![](server/14_storage_configuration.png)
「FILE SYSTEM SUMMARY」を確認する。今回の場合、/のbtrfsパーティションはこの場でフォーマットする。/boot/efiのvfatパーティション、および2つのswapパーティションはすでにフォーマット済みのためフォーマットせずに、既存の状態のまま使用する。確認したら、Doneにフォーカスを当ててEnterキーを押下する。

![](server/15_storage_configuration.png)
フォーマットによりデータが失われるという警告が表示される。Continueにフォーカスを当ててEnterキーを押下する。

### Profile setup画面
![](server/16_profile_setup.png)
任意の値を入力してから、Doneにフォーカスを当ててEnterキーを押下する。

### SSH Setup画面
![](server/17_ssh_setup.png)
「Install OpenSSH server」にチェックを入れ、「from GitHub」を選択し、ユーザー名を入力してから、Doneにフォーカスを当ててEnterキーを押下する。

![](server/18_ssh_setup.png)
SSHキーを確認してから、Yesにフォーカスを当ててEnterキーを押下する。

### Features Server Snaps画面
![](server/19_features_server_snaps.png)
必要なものがあればそれらにチェックを入れてから、Doneにフォーカスを当ててEnterキーを押下する。なお、ここでインストールできるのはSnap版のアプリケーションであるが、例えば一般的にDockerはSnap版ではないものをインストールする。

### Installing system画面
![](server/20_installing_system.png)
インストールが始まるため、待つ。

### Install complete!画面
![](server/21_install_complete.png)
インストールが終わったら、Ctrl + Alt + F2キーを押下して、コンソール画面に入る。

### コンソール画面
まず、スクリプトをダウンロードして、そのディレクトリーに移動する。
```
sudo apt install git
git clone --depth=1 https://github.com/hydratlas/tips
cd tips/debian-and-ubuntu-tips/install-ubuntu-with-btrfs
```

lsblkコマンドでインストール先のストレージの名前（sdX）を確認する。
```
lsblk -f -e 7
```

インストール先のストレージを、スクリプトによってBtrfsをRAID 1にするとともに、Snapperに対応したサブボリュームのレイアウトにし、さらにfstabとブートローダーをそれに合わせた構成に更新する。ただし、1台だけ指定した場合には、RAID 1ではなくシングル構成にする。第一引数のストレージから第二引数のストレージにコピーしてRAID 1構成にするため、引数の順番には注意すること。
```
sudo bash -eux btrfs2.sh sdX sdX
```

終わったら再起動する。
```
sudo reboot
```
