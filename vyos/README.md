# VyOS
## インストール
まずライブ実行する。ログイン時のデフォルト名とパスワードはともに`vyos`である。ログインしたら`install image`コマンドを実行する。

1. Welcome to VyOS installation!<br>
This command will install VyOS to your permanent storage.<br>
Would you like to continue? [y/N]<br>
↳「y」と入力してエンター
1. What would you like to name this image? (Default: 1.5-rolling-202411270007)<br>
↳無入力でエンター
1. Please enter a password for the "vyos" user:<br>
↳パスワードを入力してエンター
1. Please confirm password for the "vyos" user:<br>
↳パスワードを入力してエンター
1. What console should be used by default? (K: KVM, S: Serial)? (Default: S)<br>
↳無入力でエンター
1. Probing disks<br>
1 disk(s) found<br>
The following disks were found:<br>
Drive: /dev/sda (16.0 GB)<br>
Which one should be used for installation? (Default: /dev/sda)<br>
↳無入力でエンター
1. Installation will delete all data on the drive. Continue? [y/N]<br>
↳「y」と入力してエンター
1. Searching for data from previous installations<br>
No previous installation found<br>
Would you like to use all the free space on the drive? [Y/n]<br>
↳「y」と入力してエンター
1. Creating partition table...<br>
The following config files are available for boot:<br>
        1: /opt/vyatta/etc/config/config.boot<br>
        2: /opt/vyatta/etc/config.boot.default<br>
Which file would you like as boot config? (Default: 1)<br>
↳無入力でエンター
1. Creating temporary directories<br>
Mounting new partitions<br>
Creating a configuration file<br>
Copying system image files<br>
Installing GRUB configuration files<br>
Installing GRUB to the drive<br>
Cleaning up<br>
Unmounting target filesystems<br>
Removing temporary files<br>
The image installed successfully; please reboot now.<br>
↳「poweroff now」と入力してエンター

シャットダウンしたら、ISOイメージを取り外す。

なお、`qemu-guest-agent`は2024年12月にデフォルトでは入っていないようになった。 [⚓ T6942 Remove VM guest agents from the generic flavor for the rolling release](https://vyos.dev/T6942)

## 初期設定
### シリアルコンソールが太字になってしまうのを解除
```sh
sudo tee "/config/scripts/setup_unbold_the_console.sh" << EOS > /dev/null &&
#!/bin/bash
cp /config/scripts/unbold_the_console.sh /etc/profile.d/unbold_the_console.sh
EOS
sudo chmod 755 "/config/scripts/setup_unbold_the_console.sh" &&
sudo tee "/config/scripts/unbold_the_console.sh" << EOS > /dev/null &&
#!/bin/bash
echo -e "\e[0m"
EOS
sudo chmod 644 /config/scripts/unbold_the_console.sh &&
sudo tee -a "/config/scripts/vyos-postconfig-bootup.script" \
  <<< "/config/scripts/setup_unbold_the_console.sh" > /dev/null
```

### 設定
```sh
/bin/vbash << EOS
source /opt/vyatta/etc/functions/script-template
configure
set system host-name 'router-01'
set system time-zone 'Asia/Tokyo'
commit && save && exit
EOS
```

## 基本的な設定
### eth0にIPv4のDHCPを設定
```sh
/bin/vbash << EOS
source /opt/vyatta/etc/functions/script-template
configure
set interfaces ethernet eth0 address dhcp
set system name-server eth0
run show interfaces
commit && save && exit
EOS
```

### eth0にIPv6のRAを設定
```sh
/bin/vbash << EOS
source /opt/vyatta/etc/functions/script-template
configure
set interfaces ethernet eth0 ipv6 address autoconf
commit && save && exit
EOS
```

### 通信を確認
```sh
ping google.com
```

### インターフェースのオフ、オン
```sh
IF_NAME=eth0 &&
/bin/vbash << EOS
source /opt/vyatta/etc/functions/script-template
configure
set interfaces ethernet ${IF_NAME} disable
commit
save
delete interfaces ethernet ${IF_NAME} disable
commit && save && exit
EOS
```

### 現在の設定を確認
```sh
show configuration

show configuration commands
```

### ログを表示
```sh
monitor log
show log tail
```

### DHCPサーバーに関して、リース情報を表示
```sh
show dhcp server leases
```

### DHCPサーバーに関して、リース情報を削除
```sh
show dhcp server leases | grep -Eo '([0-9]{1,3}\.){3}[0-9]{1,3}' | while read -r ip; do
    clear dhcp-server lease "$ip"
done
```

### DHCPサーバーに関して、特定のホストのリース情報を削除
```sh
hostname="aaa" &&
show dhcp server leases | awk '$10 == '"\"${hostname}\""' {print $1}' | while read -r ip; do
    clear dhcp-server lease "$ip"
done
```

### 初期化
```sh
/bin/vbash << EOS
source /opt/vyatta/etc/functions/script-template
configure
load /opt/vyatta/etc/config.boot.default
commit && save && exit
EOS
```

## 応用的な設定
### Lokiにログを送信
```sh
/bin/vbash << EOS
source /opt/vyatta/etc/functions/script-template
configure
set service monitoring telegraf loki url http://<hostname>
set service monitoring telegraf loki metric-name-label metric
commit && save && exit
EOS
```
`metric-name-label`の値にハイフン(-)は使えない。

Telegrafに渡っている設定は`/run/telegraf/telegraf.conf`から確認できる。

### Node Exporter
```sh
add container image quay.io/prometheus/node-exporter:latest &&
/bin/vbash << EOS
source /opt/vyatta/etc/functions/script-template
configure
set container name node-exporter allow-host-networks
set container name node-exporter description 'Node Exporter'
set container name node-exporter image 'quay.io/prometheus/node-exporter:latest'
set container name node-exporter port node-exporter destination '9100'
set container name node-exporter port node-exporter source '9100'
set container name node-exporter port node-exporter protocol 'tcp'
set container name node-exporter volume hostroot destination '/host'
set container name node-exporter volume hostroot source '/'
set container name node-exporter volume hostroot mode ro
commit && save && exit
EOS
```
`http://<hostname>:9100/metrics`にアクセスして動作を確認できる。再起動するときは`restart container node-exporter`コマンドで再起動させる。

### 自動アップデートの設定
#### REST API用のキーのセットアップ
```sh
REST_KEY="$(uuidgen)" &&
KEY_NAME="main" &&
/bin/vbash << EOS &&
source /opt/vyatta/etc/functions/script-template
configure
set service https api rest
set service https listen-address 127.0.0.1
set service https api keys id ${KEY_NAME} key ${REST_KEY}
show service https api keys
commit && save && exit
EOS
curl -k --location --request POST 'https://localhost/retrieve' \
    --form data='{"op": "showConfig", "path": []}' \
    --form key="${REST_KEY}"
```

#### アップデーター一式の設定
```sh
SCRIPT_FILENAME="vyos-updater.sh" &&
SETUP_SCRIPT_FILENAME="setup-vyos-updater.sh" &&
ENV_FILENAME="vyos-updater.env" &&
SERVICE_FILENAME="vyos-updater.service" &&
TIMER_FILENAME="vyos-updater.timer" &&
sudo tee "/config/scripts/${SCRIPT_FILENAME}" << EOS > /dev/null &&
#!/bin/vbash
source /opt/vyatta/etc/functions/script-template

NEW_IMAGE_URL=\$(wget -q -O - "https://api.github.com/repos/vyos/vyos-rolling-nightly-builds/releases/latest" | grep browser_download_url | head -n 1 | cut -d\\" -f4)
if [ -z "\${NEW_IMAGE_URL}" ]; then
    exit 0
fi
echo "Download URL: \${NEW_IMAGE_URL}"
DATA='{"op": "add", "url": "'"\${NEW_IMAGE_URL}"'"}'
curl --silent -k --location --request POST 'https://localhost/image' --form data="\${DATA}" --form key="\${REST_KEY}" > /dev/null || exit 0
echo "Download Completed"

OLD_IMAGE_NAME="\$(run show system image | tail -n 1 | grep -iv "yes" | sed 's/^ *//;s/ *$//')"
if [ -n "\${OLD_IMAGE_NAME}" ]; then
    DATA='{"op": "delete", "name": "'"\${OLD_IMAGE_NAME}"'"}'
    curl --silent -k --location --request POST 'https://localhost/image' --form data="\${DATA}" --form key="\${REST_KEY}" > /dev/null
    echo "Delete: \${OLD_IMAGE_NAME}"
fi

run reboot now
EOS
sudo chmod 755 "/config/scripts/${SCRIPT_FILENAME}" &&
sudo tee "/config/scripts/${SETUP_SCRIPT_FILENAME}" << EOS > /dev/null &&
#!/bin/bash
set -e
cp /config/scripts/${SERVICE_FILENAME} /etc/systemd/system/${SERVICE_FILENAME}
cp /config/scripts/${TIMER_FILENAME} /etc/systemd/system/${TIMER_FILENAME}
systemctl enable ${TIMER_FILENAME}
EOS
sudo chmod 755 "/config/scripts/${SETUP_SCRIPT_FILENAME}" &&
sudo tee "/config/scripts/${ENV_FILENAME}" << EOS > /dev/null &&
REST_KEY="${REST_KEY}"
EOS
sudo chmod 600 "/config/scripts/${ENV_FILENAME}" &&
sudo tee "/config/scripts/${SERVICE_FILENAME}" << EOS > /dev/null &&
[Unit]
Description=Update VyOS to the latest rolling release

[Service]
Type=oneshot
EnvironmentFile=/config/scripts/${ENV_FILENAME}
ExecStart=/bin/vbash /config/scripts/${SCRIPT_FILENAME}
StandardOutput=journal
StandardError=journal
EOS
sudo tee "/config/scripts/${TIMER_FILENAME}" << EOS > /dev/null &&
[Unit]
Description=Run VyOS update monthly

[Timer]
OnCalendar=monthly
RandomizedDelaySec=28d 
Persistent=true

[Install]
WantedBy=timers.target
EOS
sudo tee -a "/config/scripts/vyos-postconfig-bootup.script" <<< "/config/scripts/${SETUP_SCRIPT_FILENAME}" > /dev/null
```

#### 再起動して設定を完了させる
```sh
reboot now
```

#### 確認
```sh
systemctl status vyos-updater.timer
systemctl status vyos-updater.service
show system image
```

#### すぐに実行
```sh
sudo systemctl start vyos-updater.service
```
