# Ubuntu 24.04またはUbuntu Server 24.04をBtrfs (RAID 1)でセットアップ
手順および補助スクリプトです。

## 手順
- [Ubuntu 24.04](desktop.md)
- [Ubuntu Server 24.04](server.md)

## 前提
UEFIブートの必要があります。

## 解説
### 新規インストール時
btrfs1.shはインストールの前段階で使用します。1台のストレージデバイスをFAT、SwapおよびBtrfs用の3つにパーティションを切り分け、FATおよびSwapはフォーマットします。FATのサイズは約256MiB、Swapのサイズは約3.75GiB、Btrfsのサイズは残りすべてです。

btrfs1.shのコマンド例は次のとおりです。以下、sdXは例であって、マシンによって異なります。
```bash
sudo bash -x btrfs1.sh sda
sudo bash -x btrfs1.sh sdb
```

btrfs1.shによって作るパーティションの構成と、各パーティションのファイルシステムは次のとおりです。
- 1台目のSSD
  - /dev/sda1 (FAT | Formatting with btrfs1.sh)
  - /dev/sda2 (Swap | Formatting with btrfs1.sh)
  - /dev/sda3 (Btrfs | Formatting in the installer)
- 2台目のSSD
  - /dev/sdb1 (FAT | Formatting with btrfs1.sh)
  - /dev/sdb2 (Swap | Formatting with btrfs1.sh)
  - /dev/sdb3 (Btrfs | Configure RAID 1 with btrfs2.sh)

Ubuntuのインストーラーを使って、sda3にBtrfsでUbuntuをインストールします。インストールが完了すると、ルートファイルシステムは次のようになります。
- /dev/sda3 (Btrfs single)
  - /target (Mount point after reboot: /)

btrfs2.shはインストールの後段階で使用します。UbuntuがインストールされたBtrfsをRAID 1化およびサブボリューム化します。また、加えて、起動時にRAID 1を構成するストレージが1台故障していたときでも、起動できるメニューエントリーをGRUBに追加します。これはカーネルパラメータにrootflags=degradedを付加したものです。

btrfs2.shのコマンド例は次のとおりです。sda3からsdb3にRAID 1化します。なお、引数を1つだけ指定すると、RAID 1化は行いません。
```bash
sudo bash -eux btrfs2.sh sda sdb
```

btrfs2.shの処理が完了すると、ルートファイルシステムは次のようになります。
- /dev/sda3 (Btrfs RAID 1) | /dev/sdb3 (Btrfs RAID 1)
  - /mnt/@ (Mount point after reboot: /)
  - /mnt/@root (Mount point after reboot: /root)
  - /mnt/@home (Mount point after reboot: /home)
  - /mnt/@var_log (Mount point after reboot: /var/log)
  - /mnt/@snapshots (Mount point after reboot: /.snapshots)

スクリプトが設定する、`/etc/fstab`におけるBtrfsのマウントオプションはSSD向けに最適化されています(noatime)。ただし、ssdおよびdiscard=asyncマウントオプションはほとんどの場合で自動的に設定されるため、スクリプトによって明示的に指定しません。ssdマウントオプションは`cat /sys/block/XXX/queue/rotational`が0であれば自動的に設定されます。btrfs2.shの処理後に`/etc/fstab`を手動で編集することによってカスタマイズすることができます。

### 上書きインストール時
基本的には新規インストール時と同じです。相違がある部分について解説します。上書きインストールというのは、既存のルート(/)をスナップショットに保存した上で、一時的なストレージに新しくインストールしたルートに差し替えることを指します。

btrfs1.shによって作るパーティションの構成と、各パーティションのファイルシステムは次のとおりです。
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

Ubuntuのインストーラーを使って、sdc3にBtrfsでUbuntuをインストールします。インストールが完了すると、新しいルートファイルシステムは次のようになります。
- /dev/sdc3 (Btrfs single)
  - /target (Mount point after reboot: /)

btrfs2-update.shはUbuntuがインストールされた新しいBtrfsをRAID 1化およびサブボリューム化するとともに、既存のBtrfsに差し替えます。

btrfs2-update.shのコマンド例は次のとおりです。新しくインストールしたsdc3から、既存のRAID 1構成のsda3およびsdb3にデータを差し替えます。sdc3は/targetにマウントされていることを前提にしているため、引数で指定する必要はありません。
```bash
sudo bash -eux btrfs2-update.sh sda sdb
```

btrfs2-update.shの処理が完了すると、ルートファイルシステムは次のようになります。処理が完了したらsdcは不要になります。
- /dev/sda3 (Btrfs RAID 1) | /dev/sdb3 (Btrfs RAID 1)
  - /mnt/@ (Mount point after reboot: / | New distribution)
  - /mnt/@root (Mount point after reboot: /root | Existing data)
  - /mnt/@home (Mount point after reboot: /home | Existing data)
  - /mnt/@var_log (Mount point after reboot: /var/log | Existing data)
  - /mnt/@snapshots (Mount point after reboot: /.snapshots | Existing snapshots)
  - /mnt/@snapshots/2000-01-01T00:00:00+00:00 (Existing distribution)
