# ルーターとして設定する
- Ubuntu Server 24.04を使って、IPマスカレード、DNSキャッシュサーバーおよびDHCPサーバーができるルーターを設定する
- そのように設定するルーターを2台用意して、VRRP（Virtual Router Redundancy Protocol）によって冗長性を確保する

## 変数の準備
この例は次のような構成を想定している
- IPマスカレードする内側のネットワークは2個（`eth1`および`eth2`）
  - 1以上の任意の個数を指定可能
- VRRPによる仮想IPアドレス: `192.168.2.1`および`192.168.3.1`
- ホスト名`router1`のIPアドレス: `192.168.2.2`および`192.168.3.2`
- ホスト名`router2`のIPアドレス: `192.168.2.3`および`192.168.3.3`
- DHCPによるIPアドレスの最大配布数は`192.168.n.17`から`254`までを2分割しているため、119個
  - 変更可能

```sh
sudo apt-get install -y jq &&
JSON='{
  "router_host": ["router1", "router2"],
  "outside": {
    "interface": ["eth0", "eth0"],
    "mac_address": ["XX:XX:XX:XX:XX:XX", "XX:XX:XX:XX:XX:XX"],
    "ip_address": ["nnn.nnn.nnn.nnn", "nnn.nnn.nnn.nnn"],
    "cidr": "24",
    "dns": ["nnn.nnn.nnn.nnn", "8.8.8.8"],
    "route": "nnn.nnn.nnn.nnn"
  },
  "vrrp": {
    "state": ["MASTER", "BACKUP"],
    "priority": ["100", "90"],
    "advert_int": "1"
  },
  "ntp": {
    "ip_address": ["162.159.200.1", "210.173.160.87"]
  },
  "inside": [
    {
      "interface": ["eth1", "eth1"],
      "mac_address": ["XX:XX:XX:XX:XX:XX", "XX:XX:XX:XX:XX:XX"],
      "ip_address": ["192.168.2.2", "192.168.2.3"],
      "virtual_ip_address": "192.168.2.1",
      "cidr": "24",
      "dhcp_range": [["192.168.2.17", "192.168.2.135"], ["192.168.2.136", "192.168.2.254"]],
      "virtual_router_id": "1"
    },
    {
      "interface": ["eth2", "eth2"],
      "mac_address": ["XX:XX:XX:XX:XX:XX", "XX:XX:XX:XX:XX:XX"],
      "ip_address": ["192.168.3.2", "192.168.3.3"],
      "virtual_ip_address": "192.168.3.1",
      "cidr": "24",
      "dhcp_range": [["192.168.3.17", "192.168.3.135"], ["192.168.3.136", "192.168.3.254"]],
      "virtual_router_id": "1"
    }
  ]
}' &&
echo "${JSON}" | jq -c "."
```

## IPマスカレード
### ネットワーク設定（Netplan）
```sh
host_index="" &&
while read -r index element; do
  if [ "${element}" = "${HOSTNAME}" ]; then
    host_index=${index}
  fi
done <<< "$(echo "${JSON}" | jq -c -r ".router_host[]" | nl -v 0)" &&
interface="$(echo "${JSON}" | jq -c -r ".outside.interface[${host_index}]")" &&
mac_address="$(echo "${JSON}" | jq -c -r ".outside.mac_address[${host_index}]")" &&
ip_address="$(echo "${JSON}" | jq -c -r ".outside.ip_address[${host_index}]")" &&
cidr="$(echo "${JSON}" | jq -c -r ".outside.cidr")" &&
dns="$(echo "${JSON}" | jq -c ".outside.dns")" &&
route="$(echo "${JSON}" | jq -c -r ".outside.route")" &&
sudo tee "/etc/netplan/90-${interface}.yaml" << EOS > /dev/null &&
network:
  version: 2
  ethernets:
    ${interface}:
      match:
        macaddress: "${mac_address}"
      addresses:
      - "${ip_address}/${cidr}"
      nameservers:
        addresses: ${dns}
      dhcp6: true
      set-name: "${interface}"
      routes:
      - to: "default"
        via: "${route}"
EOS
sudo chmod go= "/etc/netplan/90-${interface}.yaml" &&
while read -r index element; do
  interface="$(echo "${element}" | jq -c -r ".interface[${host_index}]")" &&
  mac_address="$(echo "${element}" | jq -c -r ".mac_address[${host_index}]")" &&
  ip_address="$(echo "${element}" | jq -c -r ".ip_address[${host_index}]")" &&
  cidr="$(echo "${element}" | jq -c -r ".cidr")" &&
  sudo tee "/etc/netplan/90-${interface}.yaml" << EOS > /dev/null &&
network:
  version: 2
  ethernets:
    ${interface}:
      match:
        macaddress: "${mac_address}"
      addresses:
      - "${ip_address}/${cidr}"
      set-name: "${interface}"
EOS
  sudo chmod go= "/etc/netplan/90-${interface}.yaml"
done <<< "$(echo "${JSON}" | jq -c -r ".inside[]" | nl -v 0)" &&
sudo netplan try --timeout 10
```

### IPマスカレードおよびファイアウォール設定（nftables）
#### 設定
```sh
sudo tee /etc/sysctl.d/20-ip-forward.conf << EOS > /dev/null &&
net/ipv4/ip_forward=1
EOS
sudo sysctl -p /etc/sysctl.d/20-ip-forward.conf &&
sudo apt-get install -y nftables ipcalc &&
host_index="" &&
while read -r index element; do
  if [ "${element}" = "${HOSTNAME}" ]; then
    host_index=${index}
  fi
done <<< "$(echo "${JSON}" | jq -c -r ".router_host[]" | nl -v 0)" &&
sudo nft add table ip filter &&
sudo nft add chain ip filter INPUT { type filter hook input priority 0 \; } &&
sudo nft add chain ip filter FORWARD { type filter hook forward priority 0 \; } &&
sudo nft add chain ip filter OUTPUT { type filter hook output priority 0 \; } &&
sudo nft add rule ip filter INPUT iifname "lo" accept && # ローカルホストへの入力トラフィックは許可
sudo nft add rule ip filter INPUT ct state established,related accept && # 既存の接続や関連の入力トラフィックは許可
sudo nft add table ip nat &&
sudo nft add chain ip nat postrouting { type nat hook postrouting priority 100 \; } &&
outside_interface="$(echo "${JSON}" | jq -c -r ".outside.interface[${host_index}]")" &&
outside_ip_address="$(echo "${JSON}" | jq -c -r ".outside.ip_address[${host_index}]")" &&
while read -r index element; do
  interface="$(echo "${element}" | jq -c -r ".interface[${host_index}]")" &&
  ip_address="$(echo "${element}" | jq -c -r ".ip_address[${host_index}]")" &&
  cidr="$(echo "${element}" | jq -c -r ".cidr")" &&
  network_address="$(ipcalc "${ip_address}/${cidr}" | grep -oP "(?<=^Network:) *[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+")" &&
  network_address="${network_address#"${network_address%%[![:space:]]*}"}" &&
  sudo nft add rule ip filter INPUT iifname "${interface}" ip saddr "${network_address}/${cidr}" udp dport 53 accept && # DNSクエリ(UDP)に関する入力トラフィックを許可
  sudo nft add rule ip filter INPUT iifname "${interface}" ip saddr "${network_address}/${cidr}" tcp dport 53 accept && # DNSクエリ(TCP)に関する入力トラフィックを許可
  sudo nft add rule ip filter INPUT iifname "${interface}" udp dport 67 accept && # DHCPリクエストに関する入力トラフィックを許可
  sudo nft add rule ip filter FORWARD ip saddr "${network_address}/${cidr}" oifname "${outside_interface}" accept && # ローカルネットワークから外部への転送トラフィックは許可
  sudo nft add rule ip filter FORWARD ip daddr "${network_address}/${cidr}" ct state established,related accept && # 外部からローカルネットワークへの関連の転送トラフィックは許可
  sudo nft add rule ip nat postrouting ip saddr "${network_address}/${cidr}" oifname "${outside_interface}" snat to "${outside_ip_address}" # SNATを設定
done <<< "$(echo "${JSON}" | jq -c -r ".inside[]" | nl -v 0)" &&
sudo nft add rule ip filter INPUT drop && # その他すべての入力トラフィックを拒否
sudo nft add rule ip filter FORWARD drop && # その他すべての転送トラフィックを拒否
sudo nft list ruleset | sudo tee /etc/nftables.conf > /dev/null
```
設定をリセットする際は`sudo nft flush ruleset`コマンドを実行する。

#### 削除
```sh
sudo apt-get purge -y nftables
```

### IPマスカレードおよびファイアウォール設定（ufw）
#### 設定
`ufw allow`のサービス名のリストは`/etc/services`のものが使われる。
```sh
sudo apt-get install -y ufw &&
sudo tee /etc/sysctl.d/20-ip-forward.conf << EOS > /dev/null &&
net/ipv4/ip_forward=1
EOS
sudo sysctl -p /etc/sysctl.d/20-ip-forward.conf &&
sysctl -a 2>/dev/null | grep ip_forward &&
sudo perl -p -i -e "s/^#?DEFAULT_FORWARD_POLICY=.*\$/DEFAULT_FORWARD_POLICY=\"ACCEPT\"/g" /etc/default/ufw &&
sudo perl -p -i -e "s|^#?net/ipv4/ip_forward=.*\$|net/ipv4/ip_forward=1|g" /etc/ufw/sysctl.conf &&
sudo ufw allow ssh &&
sudo ufw limit ssh &&
sudo ufw allow domain &&
sudo ufw allow bootps &&
sudo ufw allow mdns &&
sudo ufw logging medium &&
sudo apt-get install -y ipcalc moreutils &&
if [ ! -e /usr/local/bin/update_or_add_textblock ]; then
  URL="https://raw.githubusercontent.com/hydratlas/tips/refs/heads/main/scripts/update_or_add_textblock" &&
  wget --spider "${URL}" &&
  wget -O - "${URL}" | sudo tee /usr/local/bin/update_or_add_textblock > /dev/null &&
  sudo chmod a+x /usr/local/bin/update_or_add_textblock
fi &&
CODE_BLOCK1=$(cat << EOS
*nat
-F
:POSTROUTING ACCEPT [0:0]
EOS
) &&
host_index="" &&
while read -r index element; do
  if [ "${element}" = "${HOSTNAME}" ]; then
    host_index=${index}
  fi
done <<< "$(echo "${JSON}" | jq -c -r ".router_host[]" | nl -v 0)" &&
outside_interface="$(echo "${JSON}" | jq -c -r ".outside.interface[${host_index}]")" &&
CODE_BLOCK2="" &&
while read -r index element; do
  interface="$(echo "${element}" | jq -c -r ".interface[${host_index}]")" &&
  ip_address="$(echo "${element}" | jq -c -r ".ip_address[${host_index}]")" &&
  cidr="$(echo "${element}" | jq -c -r ".cidr")" &&
  network_address="$(ipcalc "${ip_address}/${cidr}" | grep -oP "(?<=^Network:) *[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+")" &&
  network_address="${network_address#"${network_address%%[![:space:]]*}"}" &&
  CODE_BLOCK2="${CODE_BLOCK2}"$'\n'"$(cat << EOS
-A POSTROUTING -s ${network_address}/${cidr} -o ${outside_interface} -j MASQUERADE
EOS
  )"
done <<< "$(echo "${JSON}" | jq -c -r ".inside[]" | nl -v 0)" &&
CODE_BLOCK3=$(cat << EOS
COMMIT
EOS
) &&
CODE_BLOCK="${CODE_BLOCK1}"$'\n'"${CODE_BLOCK2}"$'\n'"${CODE_BLOCK3}" &&
TARGET_FILE="/etc/ufw/before.rules" &&
sudo cat "${TARGET_FILE}" | update_or_add_textblock "MASQUERADE" "${CODE_BLOCK}" | sudo sponge "${TARGET_FILE}" &&
while read -r index element; do
  sudo ufw allow in on "${interface}" from "${network_address}/${cidr}" to any &&
  sudo ufw route allow in on "${interface}" from "${network_address}/${cidr}" to any &&
  sudo ufw allow in on "${interface}" from "${network_address}/${cidr}" to 224.0.0.18 comment 'keepalived multicast'
done <<< "$(echo "${JSON}" | jq -c -r ".inside[]" | nl -v 0)" &&
sudo systemctl restart ufw.service &&
sudo systemctl enable ufw.service &&
sudo ufw enable &&
sudo ufw status verbose
```

#### 確認
```sh
sudo systemctl status ufw.service
```

#### 無効化・削除
```sh
sudo ufw disable &&
sudo apt-get purge -y ufw
```

#### ログの確認
```sh
journalctl | grep "\[UFW "
```

## DNSキャッシュサーバーおよびDHCPサーバー
### 設定
```sh
sudo apt-get install -y dnsmasq
elements="$(echo "${JSON}" | jq '.ntp.ip_address[]')" &&
dns="$(echo "${JSON}" | jq -r '.outside.dns[] | "server=\(.)"')" &&
ntp="$(echo "${JSON}" | jq -r '.ntp.ip_address | join(",")')" &&
sudo tee "/etc/dnsmasq.d/base.conf" << EOS > /dev/null &&
# プレーンネーム（ドットやドメイン部分のないもの）を転送しない
domain-needed

# 非ルートアドレス空間のアドレスは転送しない
bogus-priv

# /etc/resolv.confを読み込まない
no-resolv

# 上位のDNSサーバーへの転送
${dns}

# ローカル専用ドメインをここに追加すると、これらのドメインのクエリは/etc/hostsまたはDHCPからのみ応答される。
local=/home.apra/

# これをサポートしているシステムでは、dnsmasqは、いくつかのインターフェイスでしかリッスンしていない場合でも、
# ワイルドカードアドレスをバインドする。そして、応答すべきでないリクエストを破棄する。
# これは、インターフェイスが行ったり来たりしてアドレスが変わっても動作するという利点がある。
# dnsmasqがリッスンしているインターフェースだけを本当にバインドしたい場合は、このオプションのコメントを外す。
# このオプションが必要になるのは次のような場合だけである。同じマシン上で別のネームサーバーを実行している場合。
bind-interfaces

# hosts-file内の単純な名前にドメインを自動的に追加したい場合は、これを設定する（ドメインも設定する：後述）。
expand-hosts

# dnsmasqのドメインを設定する
domain=home.apra

# NTPサーバー
dhcp-option=option:ntp-server,${ntp}
EOS
TARGET_FILE="/etc/dnsmasq.conf" &&
START_MARKER="# BEGIN INCLUDE BLOCK" &&
END_MARKER="# END INCLUDE BLOCK" &&
CODE_BLOCK=$(cat << EOS
# .confで終わるディレクトリ内のすべてのファイルを読み込む
conf-dir=/etc/dnsmasq.d/,*.conf
EOS
) &&
if ! grep -q "${START_MARKER}" "${TARGET_FILE}"; then
  echo "${START_MARKER}"$'\n'"${CODE_BLOCK}"$'\n'"${END_MARKER}" | sudo tee -a "${TARGET_FILE}" > /dev/null  
fi &&
host_index="" &&
while read -r index element; do
  if [ "${element}" = "${HOSTNAME}" ]; then
    host_index=${index}
  fi
done <<< "$(echo "${JSON}" | jq -c -r ".router_host[]" | nl -v 0)" &&
while read -r index element; do
  interface="$(echo "${element}" | jq -c -r ".interface[${host_index}]")" &&
  ip_address="$(echo "${element}" | jq -c -r ".ip_address[${host_index}]")" &&
  cidr="$(echo "${element}" | jq -c -r ".cidr")" &&
  subnet_mask="$(ipcalc "${ip_address}/${cidr}" | grep -oP "(?<=^Netmask:) *[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+")" &&
  subnet_mask="${subnet_mask#"${subnet_mask%%[![:space:]]*}"}" &&
  virtual_ip_address="$(echo "${element}" | jq -c -r ".virtual_ip_address")" &&
  dhcp_range="$(echo "${element}" | jq -r ".dhcp_range[${host_index}] | join(\",\")")" &&
  sudo tee "/etc/dnsmasq.d/${interface}.conf" << EOS > /dev/null
# インターフェース
interface=${interface}

# DHCPのアドレスの範囲
dhcp-range=tag:${interface},${dhcp_range},${subnet_mask},24h

# デフォルトルート
dhcp-option=tag:${interface},option:router,${virtual_ip_address}

# DNSサーバー
dhcp-option=tag:${interface},option:dns-server,${virtual_ip_address}

#dhcp-host=aa:bb:cc:dd:ee:ff,192.168.9.99
EOS
done <<< "$(echo "${JSON}" | jq -c -r ".inside[]" | nl -v 0)" &&
sudo systemctl restart dnsmasq.service &&
sudo systemctl enable dnsmasq.service
```

### 確認（サーバー側）
```sh
sudo systemctl status dnsmasq.service
```

## VRRP（Virtual Router Redundancy Protocol）
### 設定
```sh
sudo apt-get install -y keepalived &&
sudo tee "/etc/keepalived/keepalived.conf" << EOS > /dev/null &&
include /etc/keepalived/conf.d/*.conf
EOS
sudo mkdir -p /etc/keepalived/conf.d &&
host_index="" &&
while read -r index element; do
  if [ "${element}" = "${HOSTNAME}" ]; then
    host_index=${index}
  fi
done <<< "$(echo "${JSON}" | jq -c -r ".router_host[]" | nl -v 0)" &&
vrrp_state="$(echo "${JSON}" | jq -c -r ".vrrp.state[${host_index}]")" &&
vrrp_priority="$(echo "${JSON}" | jq -c -r ".vrrp.priority[${host_index}]")" &&
vrrp_advert_int="$(echo "${JSON}" | jq -c -r ".vrrp.advert_int")" &&
while read -r index element; do
  interface="$(echo "${element}" | jq -c -r ".interface[${host_index}]")" &&
  virtual_router_id="$(echo "${element}" | jq -c -r ".virtual_router_id")" &&
  virtual_ip_address="$(echo "${element}" | jq -c -r ".virtual_ip_address")" &&
  cidr="$(echo "${element}" | jq -c -r ".cidr")" &&
  sudo tee "/etc/keepalived/conf.d/${interface}.conf" << EOS > /dev/null
vrrp_instance VI_${interface} {
    state ${vrrp_state}
    interface ${interface}
    virtual_router_id ${virtual_router_id}
    priority ${vrrp_priority}
    advert_int ${vrrp_advert_int}
    virtual_ipaddress {
        ${virtual_ip_address}/${cidr}
    }
}
EOS
done <<< "$(echo "${JSON}" | jq -c -r ".inside[]" | nl -v 0)" &&
sudo systemctl restart keepalived.service &&
sudo systemctl enable keepalived.service
```

### 確認
```sh
sudo systemctl status keepalived.service
```

### 確認（クライアント側）
```sh
ip a
ip r
cat /run/systemd/resolve/resolv.conf
dig hostname.home.apra
dig www.google.com
```
