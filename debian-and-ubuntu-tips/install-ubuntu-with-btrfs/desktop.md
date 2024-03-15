# Ubuntu 23.10をBtrfs (RAID 1)でセットアップ
## ステップ1
### GNU GRUB画面
![](desktop/001_grub.png)
「Try or Install Ubuntu」にフォーカスを当てて、Enterキーを押下する。

### Ubuntuへ、ようこそ。（Welcome to Ubuntu）画面
![](desktop/002_welcome_to_ubuntu.png)
「日本語」を選択して、「Next」ボタンをクリックする。

### Ubuntuを試してみるか、インストールします（Try or install Ubuntu）画面
![](desktop/003_try_or_install_ubuntu.png)
「Ubuntuをインストール」を選択して、「Next」ボタンをクリックする。

### キーボードレイアウト（Keyboard layout）画面
![](desktop/004_Keyboard_layout.png)
「日本語」とキーボードバリアント「日本語」を選択して、「Next」ボタンをクリックする。

### ネットワークに接続（Connect to a network）画面
![](desktop/005_connect_to_a_network.png)
「有線接続を使用」を選択して、「Next」ボタンをクリックする。

### Update available画面
![](desktop/006_update_available.png)
「Skip」ボタンをクリックする。

### アプリケーションとアップデート（Applications and updates）画面
![](desktop/007_applications_and_updates.png)
「Default installation」を選択して、「Next」ボタンをクリックする。

### インストール方法を選択（Type of installation）画面
![](desktop/008_type_of_installation_1.png)
![](desktop/008_type_of_installation_2.png)
![](desktop/008_type_of_installation_3.png)
1. 左上の「アクティビティ」ボタンをクリック
1. 左下の「アプリケーションを表示する」ボタンをクリック
1. 「Taminal」をクリック

### ターミナル画面
![](desktop/009_taminal.png)
スクリプトによってインストール先のストレージ2台をフォーマットする。

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

終わったら、ターミナル画面を閉じる。

## ステップ2
### インストール方法を選択（Type of installation）画面
![](desktop/101_type_of_installation.png)
「手動パーティショニング」を選択して、「Next」ボタンをクリックする。

### 手動パーティショニング（Manual partitioning）画面
![](desktop/102_manual_partitioning_1.png)
![](desktop/102_manual_partitioning_2.png)
![](desktop/102_manual_partitioning_3.png)
1. ブートローダーをインストールするデバイスとして、一台目のストレージを選択する
1. 一台目のストレージの第三パーティション（この場合は「vda3」）を選択
1. 「変更」ボタンをクリック
1. 「パーティションを編集する」画面が表示されるので、Btrfsと/を選択して、「OK」ボタンをクリックする
1. 「Next」ボタンをクリックする

### インストールの準備完了（Ready to install）画面
![](desktop/103_ready_to_install.png)
確認して、「インストール」ボタンをクリックする。

### タイムゾーンを選択してください。（Select your timezone）画面
![](desktop/104_select_your_timezone.png)
「Tokyo」と「Asia/Tokyo」を選択して、「Next」ボタンをクリックする。

### アカウントの設定（Set up your account）画面
![](desktop/105_set_up_your_account.png)
任意の値を入力して、「Next」ボタンをクリックする。

### テーマを選択してください。（Choose your theme）画面
![](desktop/106_choose_your_theme.png)
任意のテーマを選択して、「Next」ボタンをクリックする。

### インストールが完了しました（Installation complete）画面
![](desktop/107_installation_complete_1.png)
![](desktop/107_installation_complete_2.png)
![](desktop/107_installation_complete_3.png)
1. 左上の「アクティビティ」ボタンをクリック
1. 左下の「アプリケーションを表示する」ボタンをクリック
1. 「Taminal」をクリック

### ターミナル画面
![](desktop/108_taminal.png)
スクリプトのディレクトリーに移動する。
```
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

終わったら、ターミナル画面を閉じる。

## ステップ3
### Installation complete画面
![](desktop/201_installation_complete.png)
「今すぐ再起動する」ボタンをクリックする。
