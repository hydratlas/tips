# Proxmox VE
## インストール
1. Target harddisk
1. Advanced optiosから、ZFS (RAID 1)（1台だけの場合はRAID 0）
1. compressはzstd
1. ARC max sizeは、ストレージの1TBあたり1GiBが目安。上限は搭載している物理メモリの3/4もしくは、1GBを残した全部
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

## サブスクリプションの広告を削除
```bash
sed -Ezi.bak "s/(Ext.Msg.show\(\{\s+title: gettext\('No valid sub)/void\(\{ \/\/\1/g" /usr/share/javascript/proxmox-widget-toolkit/proxmoxlib.js && systemctl restart pveproxy.service
```

## 自動アップデート
### パッケージをインストール
```bash
apt-get update -y &&
apt-get install -y unattended-upgrades apt-listchanges
```

### 設定ファイルを作成
```bash
tee /etc/apt/apt.conf.d/50unattended-upgrades << 'EOF' > /dev/null
Unattended-Upgrade::Origins-Pattern {
        "origin=Debian,codename=${distro_codename}-security,label=Debian-Security";
};

Unattended-Upgrade::Automatic-Reboot "false";
EOF
```

### 自動アップデートを有効化
```bash
echo 'unattended-upgrades unattended-upgrades/enable_auto_updates boolean true' | debconf-set-selections
```

## VM/CTの名前を後から変更
```bash
qm set <vmid> --name <name>
```

## ノード削除
Proxmox VE Administration Guide
https://pve.proxmox.com/pve-docs/pve-admin-guide.html#_remove_a_cluster_node

加えてcorosync.confから、削除したノードの情報を削除する。
```bash
nano /etc/pve/corosync.conf
```

## クリップボードからテキストを貼り付け
1. ブラウザに[Tampermonkey](https://www.tampermonkey.net/)拡張機能をインストール
1. [Copy/Paste for noVNC Proxmox](https://gist.github.com/amunchet/4cfaf0274f3d238946f9f8f94fa9ee02)を開く
1. `noVNCCopyPasteProxmox.user.js`の「Raw」ボタンを押す
1. Tampermonkeyのスクリプトインスロール画面が表示されるためインストールする
1. Proxmox VEで仮想マシンのコンソールをnoVNCで開く
1. 右クリックから「貼り付け」を押す

## Ansible実行用の準備
### APIトークンの取得とアクセス権限の設定
1. WebUIの「データセンター」→「アクセス権限」→「ユーザ」→「追加」からユーザーを作る
    1. ユーザ名：`ansible-runner`
    1. レルム：`Proxmox VE authentication server`
    1. パスワード：（任意の値）
    1. グループ：（なし）
1. WebUIの「データセンター」→「アクセス権限」→「API トークン」→「追加」からAPIトークンを作る
    1. ユーザ：`ansible-runner@pve`
    1. トークンID：`ansible-runner-202501`
    1. →APIトークンのIDとシークレットを記録
1. WebUIの「データセンター」→「アクセス権限」→「追加」→「API トークンのアクセス権限」からAPIトークンのアクセス権限を作る
    1. パス：`/`
    1. API トークン：`ansible-runner@pve!ansible-runner-202501`
    1. ロール：Administrator
    1. 継承：チェック

### Python環境の構築
`uv`を使っている場合
```bash
uv add ansible proxmoxer requests
```

### Ansible Galaxyにおけるコレクションのインストール（不要？）
```bash
uv run ansible-galaxy collection install community.general
```

### Ansible Vaultの使用（インストール不要）
```bash
uvx --from ansible-core ansible-vault encrypt_string '<token_secret>' --name 'pve_token_secret'
```

### Ansible Playbookの実行
```bash
uv run ansible-playbook -vvvv playbooks/aaa.yml
```

## その他
追加のユーザーはRealm「Proxmox VE authentication server」で作る。Proxmox VEの基盤となるLinuxマシンに対してログインすることはできないが、Proxmox VEのウェブUIにはログインすることができ、それはProxmox VEのクラスター全体に波及する。

noVNCが開かないとき
```bash
/usr/bin/ssh -e none -o 'HostKeyAlias=<hostname>' root@<IP address> /bin/true
```

LinuxではディスプレーをVirtIO-GPUにする。

Proxmox VEのroot@pamをLDAPで管理することはできない。緊急用アカウントとして使うとよい。
