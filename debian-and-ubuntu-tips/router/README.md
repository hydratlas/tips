# ルーターとして設定する
- Ubuntu Server 24.04を使って、SNAT、DNSキャッシュサーバーおよびDHCPサーバーができるルーターを設定する
  - DNSキャッシュサーバーおよびDHCPサーバーはオンで、SNATはオフのネットワークセグメントも対応可能
- そのように設定するルーターを2台用意して、VRRP（Virtual Router Redundancy Protocol）によって冗長性を確保する

## 変数の準備
この例は次のような構成を想定している
- SNATをする内側のネットワークは2個（`eth1`および`eth2`）
  - 1以上の任意の個数を指定可能
- VRRPによる仮想IPアドレス: `192.168.2.1`および`192.168.3.1`
- ホスト名`router1`のIPアドレス: `192.168.2.2`および`192.168.3.2`
- ホスト名`router2`のIPアドレス: `192.168.2.3`および`192.168.3.3`
- DHCPによるIPアドレスの最大配布数は`192.168.n.17`から`254`までを2分割しているため、119個
  - 変更可能
- `virtual_router_id`は`1`としているが、`0`から`255`までの範囲で同じネットワークの別のVRRPと重ならない値にする

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
      "nat": {
        "is_enabled": true
      },
      "dhcp_range": [["192.168.2.17", "192.168.2.135"], ["192.168.2.136", "192.168.2.254"]],
      "virtual_router_id": "1"
    },
    {
      "interface": ["eth2", "eth2"],
      "mac_address": ["XX:XX:XX:XX:XX:XX", "XX:XX:XX:XX:XX:XX"],
      "ip_address": ["192.168.3.2", "192.168.3.3"],
      "virtual_ip_address": "192.168.3.1",
      "cidr": "24",
      "nat": {
        "is_enabled": true
      },
      "dhcp_range": [["192.168.3.17", "192.168.3.135"], ["192.168.3.136", "192.168.3.254"]],
      "virtual_router_id": "1", 
      "dhcp_hosts": [
        {
          "hostname": "client1",
          "ip_address": "192.168.3.10",
          "mac_address": "XX:XX:XX:XX:XX:XX"
        }
      ]
    }
  ]
}' &&
echo "${JSON}" | jq -c "."
```

## 関数の準備
- setup_netplan
- setup_keepalived
- setup_nftables
- setup_dnsmasq
```sh
eval "$(wget -q -O - "https://raw.githubusercontent.com/hydratlas/tips/refs/heads/main/scripts/router")"
```
中身は[router](/scripts/router)を参照。

## ネットワーク設定（Netplan）
```sh
setup_netplan "${JSON}"
```
やりなおすときは、そのままやりなおして構わない。

## VRRP（Virtual Router Redundancy Protocol）
### 設定
```sh
setup_keepalived "${JSON}"
```
やりなおすときは、そのままやりなおして構わない。

Dnsmasqで`bind-dynamic`を指定しない場合には、フェイルオーバー時に（IPアドレス変更時に）Dnsmasqが機能しないので、フェイルオーバー時にDnsmasqを再起動させるようにする。この再起動のスクリプトではroot権限が必要なため、このスクリプトを使う際には`script_user`は`root`に設定する必要がある。

### テスト
Dnsmasqが動いているかどうかでフェイルオーバーを行うため、Dnsmasqをインストールした後に行う。
```sh
sudo systemctl stop dnsmasq.service
sudo systemctl start dnsmasq.service
```

## IPマスカレードおよびファイアウォール設定（nftables）
### 設定
```sh
setup_nftables "${JSON}"
```
やりなおすときは、そのままやりなおして構わない。

### 現在の永続的な設定の確認
```sh
cat /etc/nftables.conf
```

### SNATのログ確認
```sh
journalctl --dmesg --no-pager -n 1000 | grep "nft snat:"
```

## DNSキャッシュサーバーおよびDHCPサーバー
### 設定
```sh
setup_dnsmasq "${JSON}"
```
やりなおすときは、そのままやりなおして構わない。

### 確認（クライアント側）
```sh
ip a
ip r
cat /run/systemd/resolve/resolv.conf
dig hostname.home.apra
watch dig "@$(resolvectl status | grep 'DNS Servers' | awk '{print $3}')" google.com
```
`watch `を前に付けると1秒間隔で自動的に取得できる。