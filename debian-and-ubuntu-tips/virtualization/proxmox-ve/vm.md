
# VM作成
以下で、クラウドイメージとCloud-initを使い、QEMUゲストエージェント(qemu-guest-agent)が有効な状態で起動させる方法を示す。

## イメージのダウンロード
### 概要
Proxmox VEのストレージ（local）画面でイメージをダウンロードする。クラウドイメージが、仮想マシンに最適化されていて、なおかつ固有のすぐに起動できる状態で用意されているため便利である。

Ubuntuの場合は、[Ubuntu Cloud Images - the official Ubuntu images for public clouds, Openstack, KVM and LXD](https://cloud-images.ubuntu.com/)からダウンロードする。ダウンロードするファイルの例：[https://cloud-images.ubuntu.com/minimal/releases/noble/release/ubuntu-24.04-minimal-cloudimg-amd64.img]()

Debianの場合は[Debian Official Cloud Images](https://cloud.debian.org/images/cloud/)からダウンロードする。拡張子が.qcow2のものをダウンロードするが、Proxmox VEでは拡張子.imgしか受け付けないため、Proxmox VE上での保存ファイル名では拡張子を.imgにする。ダウンロードするファイルの例：[https://cloud.debian.org/images/cloud/bookworm-backports/latest/debian-12-backports-genericcloud-amd64.qcow2]()

AlmaLinuxの場合は[Generic Cloud (Cloud-init) | AlmaLinux Wiki](https://wiki.almalinux.org/cloud/Generic-cloud.html)からダウンロードする。ダウンロードするファイルの例：[https://repo.almalinux.org/almalinux/9/cloud/x86_64/images/AlmaLinux-9-GenericCloud-latest.x86_64.qcow2]()

以下の関数によってコマンドラインからもダウンロードできる。

### 関数の準備
- image_downloader
  - ファイルが存在しないか、1週間以上古かったらダウンロード
  - 拡張子は`.img`に統一
```sh
eval "$(wget -q -O - "https://raw.githubusercontent.com/hydratlas/tips/refs/heads/main/scripts/proxmox-ve")"
```
中身は[proxmox-ve](/scripts/proxmox-ve)を参照。

### 関数の実行
```sh
image_downloader https://cloud.debian.org/images/cloud/bookworm-backports/latest/debian-12-backports-genericcloud-amd64.qcow2 # Debian 12
image_downloader https://cloud-images.ubuntu.com/minimal/releases/noble/release/ubuntu-24.04-minimal-cloudimg-amd64.img # Ubuntu 24.04
image_downloader https://repo.almalinux.org/almalinux/9/cloud/x86_64/images/AlmaLinux-9-GenericCloud-latest.x86_64.qcow2 # AlmaLinux 9
```

## VMの作成
### スニペットの準備
#### スニペットの有効化
- Proxmox VEの画面から「データセンター」→「ストレージ」を選択
- リストから「local」を選択して「編集」ボタンを押す
- 複数選択の「内容」に「スニペット」が含まれるようにする

### スニペットの配置
```sh
tee "/var/lib/vz/snippets/qemu-guest-agent.yaml" << EOS > /dev/null
#cloud-config
packages: [qemu-guest-agent]
runcmd: [systemctl enable --now qemu-guest-agent]
EOS
```

### 関数の準備
- vm_create
  - 適当なマシン構成（あとから`qm set`コマンドで変更可能）
  - スニペット`qemu-guest-agent.yaml`を追加
- vm_start
  - ホストと同じタイムゾーンの設定
  - GRUBをシリアルコンソールに出力
  - シリアルコンソール向けに`apt`コマンドのプログレスバーを無効化
  - 初回の`apt-get update`コマンドを実行
```sh
eval "$(wget -q -O - "https://raw.githubusercontent.com/hydratlas/tips/refs/heads/main/scripts/proxmox-ve")"
```
中身は[proxmox-ve](/scripts/proxmox-ve)を参照。

### 実行
適宜変更して使用する。
```sh
eval "$(wget -q -O - "https://raw.githubusercontent.com/hydratlas/tips/refs/heads/main/scripts/proxmox-ve")" &&
VMID="$((RANDOM % 9900 + 100))" &&
echo "VMID: ${VMID}" &&
RANDOM_HEX=$(printf '%06X\n' $((RANDOM * 256 + RANDOM % 256))) &&
MAC_ADDRESS_0="BC:24:11:$(echo "${RANDOM_HEX}" | sed 's/../&:/g; s/:$//')" &&
echo "MAC address 0: ${MAC_ADDRESS_0}" &&
vm_create "${VMID}" "local-zfs" "local" "/var/lib/vz/template/iso/ubuntu-24.04-minimal-cloudimg-amd64.img" "8G" &&
qm set "${VMID}" \
  --name "ubuntu-${VMID}" \
  --cores 6 \
  --memory 8192 \
  --net0 "virtio=${MAC_ADDRESS_0},bridge=vmbr0" \
  --ipconfig0 ip=dhcp,ip6=dhcp \
  --ciuser "user" \
  --cipassword "$(openssl passwd -6 "p")" &&
vm_start "${VMID}" &&
vm_exec_timezone "${VMID}" &&
vm_exec_apt "${VMID}" &&
vm_exec_grub "${VMID}" &&
qm guest exec "${VMID}" -- bash -c 'DEBIAN_FRONTEND=noninteractive apt-get install -yq \
  avahi-daemon libnss-mdns \
  less nano \
  bash-completion command-not-found \
  ' | jq -r '."out-data", ."err-data"' &&
qm guest exec "${VMID}" -- bash -c 'ip a && ip r' | jq -r '."out-data", ."err-data"' &&
qm terminal "${VMID}"
```
- `--cores`は設定しない場合、そのマシンの物理コア数となる
- `import-from`はイメージファイルによって規定された容量にしかできないため、`vm_create`コマンド内で後から容量を変更している
- Cloud-initは`vm_create`コマンド内で`local-zfs:cloudinit`として設定しているが、これを`--ide0`として設定すると、`--machine pc --bios seabios`でないと動かない。`--scsi0`で設定すれば、`--machine pc --bios seabios`でも`--machine q35 --bios ovmf --efidisk0 local-zfs:0`でも動く
- `vm_exec_grub`コマンド内で、GRUBの設定を変更して、GRUBをコンソールに出力させている
- `vm_exec_timezone`コマンド内で、タイムゾーンをホストと同じものに設定している

### 実行前にSSHを設定
`START`の前に次のように実行すると、Cloud-initによってSSHの`authorized_keys`を設定できる。起動中に実行した場合は再起動が必要。
```sh
KEY_URL="https://github.com/<name>.keys" &&
KEY_FILE="$(mktemp)" &&
IMAGE_DIR="/var/lib/vz/template/iso" &&
wget -O "$KEY_FILE" "$KEY_URL" &&
qm set "${VMID}" --sshkey "${KEY_FILE}" &&
rm "$KEY_FILE"
```

### 【デバッグ】すでに作成されているVMの設定を確認
```sh
qm config "${VMID}"
```
これを参考にして`qm create`コマンドのオプションを検討する。

### 【元に戻す】停止・削除
```sh
qm stop "${VMID}" &&
qm destroy "${VMID}"
```

## VMの使用
### ホストからコマンドを実行（QEMU guest agentが必要）
```sh
qm guest exec "${VMID}" -- bash -c "uname -r && uname -n" | jq -r '."out-data", ."err-data"'
```

### シリアルコンソールに接続
```sh
qm terminal "${VMID}"
```
シリアルコンソールは同時に一つしか使用できないため、ディスプレーをSerial terminal 0 (serial0)に設定すると接続できなくなることに注意。

### シリアルコンソールで文字の装飾を解除
シリアルコンソールで文字の装飾が続いてしまったときに解除する方法。
```sh
echo -e "\e[0m"
```

## 【遺産】イメージのカスタマイズ
イメージをカスタマイズすることもできるが、`qemu-guest-agent`さえ入っていれば通常の起動後に実行できる。
```sh
IMAGE_DIR="/var/lib/vz/template/iso" &&
BASE_FILE="ubuntu-24.04-minimal-cloudimg-amd64.img" &&
CUSTOM_FILE="${BASE_FILE%.*}" && # 拡張子なし
CUSTOM_FILE="${CUSTOM_FILE}-custom.img" &&
GRUBCONF=$(cat << EOS
GRUB_CMDLINE_LINUX="quiet console=tty0 console=ttyS0,115200"
GRUB_TERMINAL_INPUT="console serial"
GRUB_TERMINAL_OUTPUT="gfxterm serial"
GRUB_SERIAL_COMMAND="serial --unit=0 --speed=115200"
EOS
) &&
apt-get install --no-install-recommends -y guestfs-tools libguestfs-tools &&
cp "${IMAGE_DIR}/${BASE_FILE}" "${IMAGE_DIR}/${CUSTOM_FILE}" &&
virt-customize -a "${IMAGE_DIR}/${CUSTOM_FILE}" --install qemu-guest-agent \
  --timezone "$(timedatectl show --property=Timezone | cut -d= -f2)" \
  --mkdir /etc/ssh/sshd_config.d \
  --write '/etc/ssh/sshd_config.d/90-local.conf:
PasswordAuthentication no
PermitRootLogin no
' \
  --run-command "echo \"${GRUBCONF}\" >> /etc/default/grub" \
  --run-command "update-grub" &&
  virt-sysprep -a "${IMAGE_DIR}/${CUSTOM_FILE}" --enable machine-id,ssh-hostkeys
```
`virt-customize`コマンドがエラーで失敗するときには`-vx`オプションを加えてデバッグする。
