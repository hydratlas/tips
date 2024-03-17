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
```
mv /etc/apt/sources.list.d/pve-enterprise.list /etc/apt/sources.list.d/pve-enterprise.list.bak &&
mv /etc/apt/sources.list.d/ceph.list /etc/apt/sources.list.d/ceph.list.bak &&
tee /etc/apt/sources.list.d/pve-no-subscription.list << 'EOF' >/dev/null &&
deb http://download.proxmox.com/debian/pve bookworm pve-no-subscription
EOF
tee /etc/apt/sources.list.d/ceph.list << 'EOF' >/dev/null
deb http://download.proxmox.com/debian/ceph-reef bookworm no-subscription
EOF
```

## サブスクリプションの広告を削除
```
sed -Ezi.bak "s/(Ext.Msg.show\(\{\s+title: gettext\('No valid sub)/void\(\{ \/\/\1/g" /usr/share/javascript/proxmox-widget-toolkit/proxmoxlib.js && systemctl restart pveproxy.service
```

## VM作成
### イメージをダウンロード
Proxmox VEのストレージ（local）画面でイメージをダウンロードする。

Ubuntuの場合は、[Ubuntu Cloud Images - the official Ubuntu images for public clouds, Openstack, KVM and LXD](https://cloud-images.ubuntu.com/)からダウンロードする。ダウンロードするファイルの例：(https://cloud-images.ubuntu.com/minimal/releases/mantic/release/ubuntu-23.10-minimal-cloudimg-amd64.img)[https://cloud-images.ubuntu.com/minimal/releases/mantic/release/ubuntu-23.10-minimal-cloudimg-amd64.img]

Debianの場合は[Debian Official Cloud Images](https://cloud.debian.org/images/cloud/)からダウンロードする。拡張子が.qcow2のものをダウンロードするが、Proxmox VEでは拡張子.imgしか受け付けないため、Proxmox VE上での保存ファイル名では拡張子を.imgにする。ダウンロードするファイルの例：[https://cloud.debian.org/images/cloud/bookworm-backports/latest/debian-12-backports-genericcloud-amd64.qcow2](https://cloud.debian.org/images/cloud/bookworm-backports/latest/debian-12-backports-genericcloud-amd64.qcow2)

### テンプレートの作成
適宜変更して使用する。

#### Ubuntuの場合
```
VMID=<num> &&
UESR=<name> &&
PASSWORD="$(openssl passwd -6 "<password>")" &&
KEY_URI=https://github.com/<name>.keys &&
KEY_FILE="$(mktemp)" && wget -O "$KEY_FILE" "$KEY_URI" &&
qm create "$VMID" \
  --name ubuntu-23.10-minimal \
  --virtio0 local-zfs:0,import-from=/var/lib/vz/template/iso/ubuntu-23.10-minimal-cloudimg-amd64.img \
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
```
VMID=<num> &&
UESR=<name> &&
PASSWORD="$(openssl passwd -6 "<password>")" &&
KEY_URI=https://github.com/<name>.keys &&
KEY_FILE="$(mktemp)" && wget -O "$KEY_FILE" "$KEY_URI" &&
qm create "$VMID" \
  --name debian-12-minimal \
  --virtio0 local-zfs:0,import-from=/var/lib/vz/template/iso/debian-12-backports-genericcloud-amd64.img \
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

## CT作成（UbuntuまたはDebian）
### 一般
Proxmox VEのストレージ（local）画面で、CTテンプレートの「テンプレート」ボタンからダウンロード。バージョン違いは[http://download.proxmox.com/images/system/](http://download.proxmox.com/images/system/)にある。

Debianの場合、IPv6は「静的」を選ばないとコンソール画面が表示されない（静的を選べば、IPアドレス、ゲートウェイは空でよい）。

### 初期設定
```
apt-get update &&
apt-get dist-upgrade &&
apt-get install -y --no-install-recommends avahi-daemon &&
timedatectl set-timezone Asia/Tokyo &&
dpkg-reconfigure --frontend noninteractive tzdata &&
systemctl disable --now systemd-timesyncd.service
```

### Podmanをインストール
```
apt-get install -y podman &&
apt-get install --no-install-recommends -y podman-docker &&
perl -p -i -e 's/^#? ?unqualified-search-registries = .+$/unqualified-search-registries = ["docker.io"]/g;' /etc/containers/registries.conf &&
touch /etc/containers/nodocker &&
tee /usr/local/bin/overlayzfsmount << EOS > /dev/null &&
#!/bin/sh
exec /bin/mount -t overlay overlay "\$@"
EOS
chmod a+x /usr/local/bin/overlayzfsmount &&
tee /etc/containers/storage.conf << EOS > /dev/null &&
[storage]
driver = "overlay"
runroot = "/run/containers/storage"
graphroot = "/var/lib/containers/storage"

[storage.options]
pull_options = {enable_partial_images = "false", use_hard_links = "false", ostree_repos=""}
mount_program = "/usr/local/bin/overlayzfsmount"

[storage.options.overlay]
mountopt = "nodev"
EOS
systemctl restart podman.service
```

### Podmanをテスト実行
```
docker run hello-world
```

### PodmanにPortainerをインストール
```
docker volume create portainer_data &&
docker run -d -p 8000:8000 -p 9443:9443 --name portainer --restart=always \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v portainer_data:/data portainer/portainer-ce:latest

# https://localhost:9443
```

### 新しいPodmanを使う（うまく動かない）
```
apt-get install --no-install-recommends -y gpg &&
source /etc/os-release &&
wget http://downloadcontent.opensuse.org/repositories/home:/alvistack/Debian_$VERSION_ID/Release.key -O alvistack_key &&
cat alvistack_key | gpg --dearmor | tee /etc/apt/trusted.gpg.d/alvistack.gpg  >/dev/null &&
echo "deb http://downloadcontent.opensuse.org/repositories/home:/alvistack/Debian_$VERSION_ID/ /" | tee /etc/apt/sources.list.d/alvistack.list &&
rm alvistack_key
```