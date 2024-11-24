
# VM作成
## イメージのダウンロード
Proxmox VEのストレージ（local）画面でイメージをダウンロードする。

Ubuntuの場合は、[Ubuntu Cloud Images - the official Ubuntu images for public clouds, Openstack, KVM and LXD](https://cloud-images.ubuntu.com/)からダウンロードする。ダウンロードするファイルの例：[https://cloud-images.ubuntu.com/minimal/releases/noble/release/ubuntu-24.04-minimal-cloudimg-amd64.img]()

Debianの場合は[Debian Official Cloud Images](https://cloud.debian.org/images/cloud/)からダウンロードする。拡張子が.qcow2のものをダウンロードするが、Proxmox VEでは拡張子.imgしか受け付けないため、Proxmox VE上での保存ファイル名では拡張子を.imgにする。ダウンロードするファイルの例：[https://cloud.debian.org/images/cloud/bookworm-backports/latest/debian-12-backports-genericcloud-amd64.qcow2]()

## イメージのカスタマイズおよびテンプレートの作成
### 変数の準備
#### Debian 12の場合
```sh
BASE_IMAGE="debian-12-backports-genericcloud-amd64.img" &&
NAME="$(basename ${BASE_IMAGE} .img)" &&
CUSTOM_IMAGE="${NAME}-custom.img"
```

#### Ubuntu 24.04の場合
```sh
BASE_IMAGE="ubuntu-24.04-minimal-cloudimg-amd64.img" &&
NAME="$(basename ${BASE_IMAGE} .img)" &&
CUSTOM_IMAGE="${NAME}-custom.img"
```

### 実行
適宜変更して使用する。`virt-customize`コマンドがエラーで失敗するときには`-vx`オプションを加えてデバッグする。テンプレートの作成時に、ディスクの容量は与えられた`.img`ファイルによって規定されている。
```sh
echo -n "vmid: " &&
read VMID &&
IMAGE_DIR="/var/lib/vz/template/iso" &&
apt-get install --no-install-recommends -y guestfs-tools libguestfs-tools &&
cp "${IMAGE_DIR}/${BASE_IMAGE}" "${IMAGE_DIR}/${CUSTOM_IMAGE}" &&
virt-customize -a "${IMAGE_DIR}/${CUSTOM_IMAGE}" \
  --install qemu-guest-agent,avahi-daemon,libnss-mdns,less,bash-completion,command-not-found,nano,whiptail \
  --timezone "$(timedatectl show --property=Timezone | cut -d= -f2)" \
  --mkdir /etc/ssh/sshd_config.d \
  --write '/etc/ssh/sshd_config.d/90-local.conf:
PasswordAuthentication no
PermitRootLogin no
' \
  --run-command 'echo "GRUB_CMDLINE_LINUX=\"quiet console=tty0 console=ttyS0,115200\"\nGRUB_TERMINAL_INPUT=\"console serial\"\nGRUB_TERMINAL_OUTPUT=\"gfxterm serial\"\nGRUB_SERIAL_COMMAND=\"serial --unit=0 --speed=115200\"" >> /etc/default/grub' \
  --run-command 'update-grub' &&
virt-sysprep -a "${IMAGE_DIR}/${CUSTOM_IMAGE}" --enable machine-id,ssh-hostkeys &&
qemu-img resize "${IMAGE_DIR}/${CUSTOM_IMAGE}" 8G &&
qm create "${VMID}" \
  --name "${NAME}" \
  --cpu x86-64-v3 \
  --cores 4 \
  --memory 8192 \
  --virtio0 "local-zfs:0,import-from=${IMAGE_DIR}/${CUSTOM_IMAGE}" \
  --bios seabios \
  --vga virtio \
  --scsihw virtio-scsi-pci \
  --ide0 local-zfs:cloudinit \
  --net0 virtio,bridge=vmbr0 \
  --serial0 socket \
  --ostype l26 \
  --boot order=virtio0 \
  --agent enabled=1 \
  --ciuser "user" \
  --cipassword "p" \
  --ipconfig0 ip=dhcp,ip6=dhcp &&
qm template "${VMID}"
```

## テンプレートからVMを作成（クローン）
WebUIから行ってもよい。
```sh
qm clone <TEMPLATE_ID> <NEW_VM_ID> --name <NEW_VM_NAME>
```

## VMの追加設定
```sh
VMID=<vmid> &&
UESR=<name> &&
PASSWORD="$(openssl passwd -6 "<password>")" &&
KEY_URI=https://github.com/<name>.keys &&
KEY_FILE="$(mktemp)" &&
IMAGE_DIR="/var/lib/vz/template/iso" &&
wget -O "$KEY_FILE" "$KEY_URI" &&
qm set "${VMID}" \
  --ciuser "${UESR}" \
  --cipassword "${PASSWORD}" \
  --sshkey "${KEY_FILE}" &&
rm "$KEY_FILE"
```
