# Proxmox VE
## インストール
1. Target harddisk
1. Advanced optiosから、ZFS (RAID 1)（1台だけの場合はRAID 0）
1. compressはzstd
1. ARC max sizeは、搭載している物理メモリの3/4もしくは、1GBを残した全部
1. CountryはJapan
1. TimezoneはAsia/Tokyo
1. Keyboard layoutはJapanese
1. Root passwordは任意の値
1. Administrator emailはroot@home.arpa
1. Management interfaceは任意のものを選択
1. Hostname (FQDN)は\<hostname\>.home.arpa
1. IP address (CIDR)は任意の値
1. Gateway addressは任意の値
1. DNS server addressは任意の値

## リポジトリを無料のものにする
### Deb822-style Format
新しいDeb822-style Formatに対応している場合（基本的にはこちらでよい）。
```bash
mv /etc/apt/sources.list.d/pve-enterprise.list /etc/apt/sources.list.d/pve-enterprise.list.bak &&
mv /etc/apt/sources.list.d/ceph.list /etc/apt/sources.list.d/ceph.list.bak &&
VERSION_CODENAME="$(grep -oP '(?<=^VERSION_CODENAME=).+' /etc/os-release | tr -d '\"')" &&
tee "/etc/apt/sources.list.d/pve-no-subscription.sources" <<- EOS > /dev/null &&
Types: deb
URIs: http://download.proxmox.com/debian/pve
Suites: $VERSION_CODENAME
Components: pve-no-subscription
EOS
tee "/etc/apt/sources.list.d/ceph.sources" <<- EOS > /dev/null
Types: deb
URIs: http://download.proxmox.com/debian/ceph-reef
Suites: $VERSION_CODENAME
Components: no-subscription
EOS
```

### One-Line-Style Format
新しいDeb822-style Formatに対応していない場合。
```bash
mv /etc/apt/sources.list.d/pve-enterprise.list /etc/apt/sources.list.d/pve-enterprise.list.bak &&
mv /etc/apt/sources.list.d/ceph.list /etc/apt/sources.list.d/ceph.list.bak &&
VERSION_CODENAME="$(grep -oP '(?<=^VERSION_CODENAME=).+' /etc/os-release | tr -d '\"')" &&
tee /etc/apt/sources.list.d/pve-no-subscription.list << EOF >/dev/null &&
deb http://download.proxmox.com/debian/pve $VERSION_CODENAME pve-no-subscription
EOF
tee /etc/apt/sources.list.d/ceph.list << EOF >/dev/null
deb http://download.proxmox.com/debian/ceph-reef $VERSION_CODENAME no-subscription
EOF
```

## サブスクリプションの広告を削除
```bash
sed -Ezi.bak "s/(Ext.Msg.show\(\{\s+title: gettext\('No valid sub)/void\(\{ \/\/\1/g" /usr/share/javascript/proxmox-widget-toolkit/proxmoxlib.js && systemctl restart pveproxy.service
```

## VM/CTの名前を後から変更
```bash
qm set <vmid> --name <name>
```

## その他
追加のユーザーはRealm「Proxmox VE authentication server」で作る。Proxmox VEの基盤となるLinuxマシンに対してログインすることはできないが、Proxmox VEのウェブUIにはログインすることができ、それはProxmox VEのクラスター全体に波及する。

noVNCが開かないとき
```bash
/usr/bin/ssh -e none -o 'HostKeyAlias=<hostname>' root@<IP address> /bin/true
```

LinuxのデスクトップOSはディスプレイをVirtIO-GPUにする。

## VM作成
### イメージをダウンロード
Proxmox VEのストレージ（local）画面でイメージをダウンロードする。

Ubuntuの場合は、[Ubuntu Cloud Images - the official Ubuntu images for public clouds, Openstack, KVM and LXD](https://cloud-images.ubuntu.com/)からダウンロードする。ダウンロードするファイルの例：[https://cloud-images.ubuntu.com/minimal/releases/mantic/release/ubuntu-23.10-minimal-cloudimg-amd64.img](https://cloud-images.ubuntu.com/minimal/releases/mantic/release/ubuntu-23.10-minimal-cloudimg-amd64.img)

Debianの場合は[Debian Official Cloud Images](https://cloud.debian.org/images/cloud/)からダウンロードする。拡張子が.qcow2のものをダウンロードするが、Proxmox VEでは拡張子.imgしか受け付けないため、Proxmox VE上での保存ファイル名では拡張子を.imgにする。ダウンロードするファイルの例：[https://cloud.debian.org/images/cloud/bookworm-backports/latest/debian-12-backports-genericcloud-amd64.qcow2](https://cloud.debian.org/images/cloud/bookworm-backports/latest/debian-12-backports-genericcloud-amd64.qcow2)

### イメージのカスタマイズ
適宜変更して使用する。

#### Ubuntu 24.04の場合
```bash
BASE_IMAGE="ubuntu-24.04-minimal-cloudimg-amd64.img" &&
CUSTOM_IMAGE="ubuntu-24.04-minimal-cloudimg-amd64-custom.img" &&
apt-get install --no-install-recommends -y guestfs-tools libguestfs-tools &&
cd /var/lib/vz/template/iso &&
cp "${BASE_IMAGE}" "${CUSTOM_IMAGE}" &&
virt-customize -a "${CUSTOM_IMAGE}" \
  --install qemu-guest-agent,avahi-daemon,libnss-mdns,less,bash-completion,command-not-found,nano,whiptail \
  --timezone Asia/Tokyo \
  --mkdir /etc/ssh/sshd_config.d \
  --write '/etc/ssh/sshd_config.d/90-local.conf:
PasswordAuthentication no
PermitRootLogin no
' \
  --run-command 'systemctl disable systemd-timesyncd.service' &&
virt-sysprep -a "${CUSTOM_IMAGE}" --enable machine-id,ssh-hostkeys
```

### テンプレートの作成
適宜変更して使用する。特にメモリーが2GiB、ディスクが3.5GiBしかないことに注意。

#### Ubuntuの場合
```bash
VMID=<num> &&
UESR=<name> &&
PASSWORD="$(openssl passwd -6 "<password>")" &&
KEY_URI=https://github.com/<name>.keys &&
KEY_FILE="$(mktemp)" && wget -O "$KEY_FILE" "$KEY_URI" &&
qm create "$VMID" \
  --name ubuntu-24.04-minimal-custom \
  --virtio0 local-zfs:0,size=3584M,import-from=/var/lib/vz/template/iso/ubuntu-24.04-minimal-cloudimg-amd64-custom.img \
  --memory 2048 \
  --cores 2 \
  --cpu x86-64-v3 \
  --bios seabios \
  --vga serial0 \
  --scsihw virtio-scsi-pci \
  --ide0 local-zfs:cloudinit \
  --net0 virtio,bridge=vmbr0 \
  --serial0 socket \
  --ostype l26 \
  --boot order=virtio0 \
  --agent enabled=1 \
  --ciuser "$UESR" \
  --cipassword "$PASSWORD" \
  --sshkey "$KEY_FILE" \
  --ipconfig0 ip=dhcp,ip6=dhcp &&
rm "$KEY_FILE" &&
qm template "$VMID"
```

#### Debianの場合
```bash
VMID=<num> &&
UESR=<name> &&
PASSWORD="$(openssl passwd -6 "<password>")" &&
KEY_URI=https://github.com/<name>.keys &&
KEY_FILE="$(mktemp)" && wget -O "$KEY_FILE" "$KEY_URI" &&
qm create "$VMID" \
  --name debian-12-minimal \
  --virtio0 local-zfs:0,size=3584M,import-from=/var/lib/vz/template/iso/debian-12-backports-genericcloud-amd64.img \
  --memory 2048 \
  --cores 2 \
  --cpu x86-64-v3 \
  --bios seabios \
  --vga serial0 \
  --scsihw virtio-scsi-pci \
  --ide0 local-zfs:cloudinit \
  --net0 virtio,bridge=vmbr0 \
  --serial0 socket \
  --ostype l26 \
  --boot order=virtio0 \
  --agent enabled=1 \
  --ciuser "$UESR" \
  --cipassword "$PASSWORD" \
  --sshkey "$KEY_FILE" \
  --ipconfig0 ip=dhcp,ip6=dhcp &&
rm "$KEY_FILE" &&
qm template "$VMID"
```

## ノード削除
Proxmox VE Administration Guide
https://pve.proxmox.com/pve-docs/pve-admin-guide.html#_remove_a_cluster_node

加えてcorosync.confから削除したノードの情報を削除する。
```bash
nano /etc/pve/corosync.conf
```

## CT作成（UbuntuまたはDebian）
### 一般
Proxmox VEのストレージ（local）画面で、CTテンプレートの「テンプレート」ボタンからダウンロードする。さらに多くのバージョンのテンプレートが[http://download.proxmox.com/images/system/](http://download.proxmox.com/images/system/)にあり、ここで任意のtar.xzやtar.zstで終わるURLをコピーした上で、「URLからダウンロード」ボタンからダウンロードできる。

Debianの場合、IPv6は「静的」を選ばないとコンソール画面が表示されない（静的を選べば、IPアドレス、ゲートウェイは空でよい）。

### 初期設定（Ubuntu）
```bash
timedatectl set-timezone Asia/Tokyo &&
dpkg-reconfigure --frontend noninteractive tzdata &&
systemctl disable --now systemd-timesyncd.service &&
apt-get install --no-install-recommends -y lsb-release &&
tee "/etc/apt/sources.list.d/ubuntu.sources" <<- EOS > /dev/null &&
Types: deb
URIs: mirror+file:/etc/apt/ubuntu-mirrors.txt
Suites: $(lsb_release --short --codename) $(lsb_release --short --codename)-updates $(lsb_release --short --codename)-backports
Components: main restricted universe multiverse
Signed-By: /usr/share/keyrings/ubuntu-archive-keyring.gpg

Types: deb
URIs: http://security.ubuntu.com/ubuntu
Suites: $(lsb_release --short --codename)-security
Components: main restricted universe multiverse
Signed-By: /usr/share/keyrings/ubuntu-archive-keyring.gpg
EOS
cat "/etc/apt/sources.list.d/ubuntu.sources" && # confirmation
tee "/etc/apt/ubuntu-mirrors.txt" <<- EOS > /dev/null &&
http://ftp.udx.icscoe.jp/Linux/ubuntu	priority:1
https://linux.yz.yamagata-u.ac.jp/ubuntu	priority:2
http://jp.archive.ubuntu.com/ubuntu
EOS
cat "/etc/apt/ubuntu-mirrors.txt" && # confirmation
if [ -f "/etc/apt/sources.list" ]; then
  rm -f "/etc/apt/sources.list"
fi &&
apt-get update &&
apt-get dist-upgrade -y &&
apt-get install --no-install-recommends -y avahi-daemon libnss-mdns
```

### 初期設定（Debian 12）
```bash
timedatectl set-timezone Asia/Tokyo &&
dpkg-reconfigure --frontend noninteractive tzdata &&
systemctl disable --now systemd-timesyncd.service &&
apt-get install --no-install-recommends -y lsb-release &&
tee "/etc/apt/sources.list.d/debian.sources" <<- EOS > /dev/null &&
Types: deb
URIs: mirror+file:/etc/apt/debian-mirrors.txt
Suites: $(lsb_release --short --codename) $(lsb_release --short --codename)-updates $(lsb_release --short --codename)-backports
Components: main contrib non-free non-free-firmware
Signed-By: /usr/share/keyrings/debian-archive-keyring.gpg

Types: deb
URIs: http://security.debian.org/debian-security
Suites: $(lsb_release --short --codename)-security
Components: main contrib non-free non-free-firmware
Signed-By: /usr/share/keyrings/debian-archive-keyring.gpg
EOS
tee "/etc/apt/debian-mirrors.txt" <<- EOS > /dev/null &&
http://ftp.jp.debian.org/debian	priority:1
https://debian-mirror.sakura.ne.jp/debian	priority:2
http://cdn.debian.or.jp/debian
EOS
if [ -f "/etc/apt/sources.list" ]; then
  rm -f "/etc/apt/sources.list"
fi &&
apt-get update &&
apt-get dist-upgrade -y &&
apt-get install --no-install-recommends -y avahi-daemon libnss-mdns
```
