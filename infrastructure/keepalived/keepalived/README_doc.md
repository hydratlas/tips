# Keepalived
```bash
setup_keepalived () {
    set -eux
    local JSON="${1}"
    sudo apt-get install -y keepalived
    sudo systemctl stop keepalived.service
    sudo tee "/etc/keepalived/keepalived.conf" << EOS > /dev/null
include /etc/keepalived/conf.d/*.conf
EOS
    sudo mkdir -p /etc/keepalived/conf.d
    local host_index=""
    while read -r index element; do
        if [ "${element}" = "${HOSTNAME}" ]; then
            host_index=${index}
        fi
    done <<< "$(echo "${JSON}" | jq -c -r ".host[]" | nl -v 0)"
    if [ -z "${host_index}" ]; then
        echo "There is no corresponding host name in the JSON."
        exit 1
    fi
    local vrrp_state="$(echo "${JSON}" | jq -c -r ".vrrp.state[${host_index}]")"
    local vrrp_priority="$(echo "${JSON}" | jq -c -r ".vrrp.priority[${host_index}]")"
    local vrrp_advert_int="$(echo "${JSON}" | jq -c -r ".vrrp.advert_int")"
    while read -r index element; do
        local interface="$(echo "${element}" | jq -c -r ".interface[${host_index}]")"
        local virtual_router_id="$(echo "${element}" | jq -c -r ".virtual_router_id")"
        local virtual_ip_address="$(echo "${element}" | jq -c -r ".virtual_ip_address")"
        local cidr="$(echo "${element}" | jq -c -r ".cidr")"
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
    done <<< "$(echo "${JSON}" | jq -c -r ".interfaces[]" | nl -v 0)"
    sudo systemctl enable --now keepalived.service
    set +eux
}
sudo apt-get install -y jq &&
JSON='{
  "host": ["app-01", "app-02"],
  "vrrp": {
    "state": ["MASTER", "BACKUP"],
    "priority": ["100", "90"],
    "advert_int": "1"
  },
  "interfaces": [
    {
      "interface": ["eth1", "eth1"],
      "virtual_ip_address": "192.168.2.1",
      "cidr": "24",
      "virtual_router_id": "1"
    },
    {
      "interface": ["eth2", "eth2"],
      "virtual_ip_address": "192.168.3.1",
      "cidr": "24",
      "virtual_router_id": "1",
    }
  ]
}' &&
echo "${JSON}" | jq -c "." &&
setup_keepalived "${JSON}"
```
`virtual_router_id`は1から255までの範囲で設定する。

確認は`sudo systemctl status keepalived.service`コマンドで行う。