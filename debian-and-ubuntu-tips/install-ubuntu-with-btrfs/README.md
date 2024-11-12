# Ubuntu 24.04またはUbuntu Server 24.04をBtrfs (RAID 1)でセットアップ
手順および補助スクリプトです。

## 手順
- [Ubuntu 24.04](desktop.md)
- [Ubuntu Server 24.04](server.md)

## 前提
UEFIブートの必要があります。

## 解説
### 新規インストール時
`btrfs1.sh`はインストールの前段階で使用します。1台のストレージデバイスをFAT、SwapおよびBtrfs用の3つにパーティションを切り分け、FATおよびSwapはフォーマットします。FATのサイズは約512MiB、Swapのサイズは約3.75GiB、Btrfsのサイズは残りすべてです。

`btrfs1.sh`のコマンド例は次のとおりです。以下、sdXは例であって、マシンによって異なります。
```sh
sudo bash -x btrfs1.sh sda
sudo bash -x btrfs1.sh sdb
```

`btrfs1.sh`によって作るパーティションの構成と、各パーティションのファイルシステムは次のとおりです。
- 1台目のSSD
  - /dev/sda1 (FAT | Formatting with btrfs1.sh)
  - /dev/sda2 (Swap | Formatting with btrfs1.sh)
  - /dev/sda3 (Btrfs | Formatting in the installer)
- 2台目のSSD
  - /dev/sdb1 (FAT | Formatting with btrfs1.sh)
  - /dev/sdb2 (Swap | Formatting with btrfs1.sh)
  - /dev/sdb3 (Btrfs | Configure RAID 1 with btrfs2.sh)

Ubuntuのインストーラーを使って、`sda3`にBtrfsでUbuntuをインストールします。インストールが完了すると、ルートファイルシステムは次のようになります。
- /dev/sda3 (Btrfs single)
  - /target (Mount point after reboot: /)

`btrfs2.sh`はインストールの後段階で使用します。UbuntuがインストールされたBtrfsをRAID 1化およびサブボリューム化します。また、加えて、起動時にRAID 1を構成するストレージが1台故障していたときでも、起動できるメニューエントリーをGRUBに追加します。これはカーネルパラメータに`rootflags=degraded`を付加したものです。

`btrfs2.sh`のコマンド例は次のとおりです。sda3からsdb3にRAID 1化します。なお、引数を1つだけ指定すると、RAID 1化は行いません。
```sh
sudo bash -eux btrfs2.sh sda sdb
```

`btrfs2.sh`の処理が完了すると、ルートファイルシステムは次のようになります。
- /dev/sda3 (Btrfs RAID 1) | /dev/sdb3 (Btrfs RAID 1)
  - /mnt/@ (Mount point after reboot: /)
  - /mnt/@root (Mount point after reboot: /root)
  - /mnt/@home (Mount point after reboot: /home)
  - /mnt/@var_log (Mount point after reboot: /var/log)
  - /mnt/@snapshots (Mount point after reboot: /.snapshots)

スクリプトが設定する、`/etc/fstab`におけるBtrfsのマウントオプションはSSD向けに最適化されています(`noatime`)。ただし、`ssd`および`discard=async`マウントオプションはほとんどの場合で自動的に設定されるため、スクリプトによって明示的に指定しません。`ssd`マウントオプションは`cat /sys/block/XXX/queue/rotational`が0であれば自動的に設定されます。`btrfs2.sh`の処理後に`/etc/fstab`を手動で編集することによってカスタマイズすることができます。

### 上書きインストール時
`btrfs1.sh`および`btrfs2.sh`を使用してインストールした後に、上書きインストールが必要になった際、`btrfs2-update.sh`を使うと既存のUbuntuをサブボリュームに退避できます。

使い方は基本的には新規インストール時と同じです。そのため相違がある部分について解説します。

`btrfs1.sh`によって作るパーティションの構成と、各パーティションのファイルシステムは次のとおりです。
- 1台目のSSD（既存の物）
  - /dev/sda1 (FAT)
  - /dev/sda2 (Swap)
  - /dev/sda3 (Btrfs)
- 2台目のSSD（既存の物）
  - /dev/sdb1 (FAT)
  - /dev/sdb2 (Swap)
  - /dev/sdb3 (Btrfs)
- 3台目のSSDまたはUSBメモリ（一時的に使う物）
  - /dev/sdc1 (FAT | Formatting with btrfs1.sh)
  - /dev/sdc2 (Swap | Formatting with btrfs1.sh)
  - /dev/sdc3 (Btrfs | Formatting in the installer)

Ubuntuのインストーラーを使って、`sdc3`にBtrfsでUbuntuをインストールします。インストールが完了すると、新しいルートファイルシステムは次のようになります。
- /dev/sdc3 (Btrfs single)
  - /target (Mount point after reboot: /)

`btrfs2-update.sh`はUbuntuがインストールされた新しいBtrfsをRAID 1化およびサブボリューム化するとともに、既存のBtrfsに差し替えます。

`btrfs2-update.sh`のコマンド例は次のとおりです。新しくインストールした`sdc3`から、既存のRAID 1構成の`sda3`および`sdb3`にデータを差し替えます。`sdc3`は`/target`にマウントされていることを前提にしているため、引数で指定する必要はありません。
```sh
sudo bash -eux btrfs2-update.sh sda sdb
```

`btrfs2-update.sh`の処理が完了すると、ルートファイルシステムは次のようになります。処理が完了したらsdcは不要になります。
- /dev/sda3 (Btrfs RAID 1) | /dev/sdb3 (Btrfs RAID 1)
  - /mnt/@ (Mount point after reboot: / | New Ubuntu)
  - /mnt/@root (Mount point after reboot: /root | Existing data)
  - /mnt/@home (Mount point after reboot: /home | Existing data)
  - /mnt/@var_log (Mount point after reboot: /var/log | Existing data)
  - /mnt/@snapshots (Mount point after reboot: /.snapshots | Existing snapshots)
  - /mnt/@snapshots/20000101T000000+0000 (Existing Ubuntu)

既存のUbuntu(`@snapshots/20000101T000000+0000`)はGRUBのメニューエントリーから起動可能です。`btrfs2-update.sh`によってメニューエントリーが追加されています。

既存のUbuntuの起動中にカーネルのアップデートが行われると（セキュリティーアップデートは自動的に行われます）、メニューエントリーが既存のUbuntuのものになり、新しいUbuntu(`@`)のメニューエントリーが破壊される可能性があります。（`update-grub`を明示的に実行しなければ破壊されない可能性もありますが、詳細は調査していません）

破壊された場合でも、`rootflags=degraded`オプション付きのメニューエントリーは起動先のパスが`@`固定になっているため、そこから`@`にある新しいUbuntuを起動できます。起動後に以下のコマンドを実行すると、新しいUbuntuのメニューエントリーを復元できます。

```sh
sudo update-grub
sudo dpkg-reconfigure shim-signed
```