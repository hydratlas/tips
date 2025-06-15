# やることリスト
完了したら見出しの先頭に【完了】と書く。

## 【完了】debian-and-ubuntu-tipsディレクトリの再編成
現在`debian-and-ubuntu-tips`ディレクトリに格納されている文書の中で、DebianとUbuntuに特化していない一般的な内容を含むディレクトリを、`ops-knowledge`直下に移動する計画。

### 移動対象ディレクトリ

#### 1. docker → ops-knowledge/docker
理由：DockerとPodmanの情報は、どのLinuxディストリビューションでも共通して使える内容が中心。パッケージインストールのコマンドのみがDebian/Ubuntu固有。

#### 2. monitoring → ops-knowledge/monitoring  
理由：Node Exporter、VictoriaMetrics、Grafana、Promtail、Lokiなどの監視スタックは、プラットフォームに依存しない。Podman Quadletを使った構成もPodmanの機能であり、Debian/Ubuntu固有ではない。

#### 3. virtualization → ops-knowledge/virtualization
理由：Proxmox VEは独自のDebianベースディストリビューションであり、その設定方法は一般的な仮想化の知識。GNOME BoxesやゲストOSの設定も、ディストリビューションに依存しない内容。

#### 4. slurm → ops-knowledge/slurm
理由：SLURMワークロードマネージャーのアーキテクチャや設定は、どのディストリビューションでも共通。パッケージ名とインストールコマンドのみがDebian/Ubuntu固有。

#### 5. keepalived → ops-knowledge/keepalived
理由：KeepalivedのVRRP設定は、どのLinuxディストリビューションでも同じ。インストールコマンドのみがDebian/Ubuntu固有。

### debian-and-ubuntu-tipsに残すディレクトリ

- auto-install: Debian/Ubuntuの自動インストール（preseed）に特化
- debootstrap: Debian/Ubuntu固有のブートストラップツール
- initial-setup: Debian/Ubuntuの初期設定に特化
- install-ubuntu-with-btrfs: Ubuntu固有のインストール手順
- router: UFWを使った設定（UFWはUbuntu固有）

### 実行手順

1. 各ディレクトリを`ops-knowledge`直下に移動
2. 移動したディレクトリ内のREADMEで、Debian/Ubuntu固有の部分（aptコマンドなど）を明記
3. `debian-and-ubuntu-tips/README.md`を更新して、移動したディレクトリへのリンクを追加
4. `ops-knowledge/README.md`を更新して、新しいディレクトリ構造を反映

## 【完了】ops-knowledge ディレクトリの階層整理案

現在 `ops-knowledge` 直下に17個のディレクトリが存在するため、もう一階層追加して整理する。

```
ops-knowledge/
├── infrastructure/          # インフラ基盤技術
│   ├── virtualization/      # 仮想化
│   │   ├── README.md
│   │   ├── gnome-boxes.md
│   │   ├── linux-guest.md
│   │   ├── windows-guest.md
│   │   └── proxmox-ve/
│   │       ├── README.md
│   │       ├── ct.md
│   │       ├── vm.md
│   │       └── install/
│   │           ├── README.md
│   │           └── [12 image files]
│   ├── docker/             # コンテナ技術
│   │   ├── README.md
│   │   ├── enable-linger.md
│   │   ├── install-docker-rootless.md
│   │   ├── install-docker.md
│   │   ├── install-podman.md
│   │   ├── run.md
│   │   └── management/
│   │       ├── README.md
│   │       ├── cockpit-podman.md
│   │       ├── dockge.md
│   │       ├── lazydocker.md
│   │       ├── portainer-agent.md
│   │       ├── portainer.md
│   │       └── watchtower.md
│   ├── hardware/           # ハードウェア管理
│   │   ├── idrac/
│   │   │   └── README.md
│   │   └── intel-amt/
│   │       └── README.md
│   ├── slurm/             # ジョブスケジューラ
│   │   └── README.md
│   ├── keepalived/        # 高可用性
│   │   └── README.md
│   ├── vyos/              # ネットワークOS
│   │   └── README.md
│   └── infra-naming-rule/ # インフラ命名規則
│       ├── ethernet-cable.md
│       └── power-cable.md
├── platforms/              # プラットフォーム別
│   ├── debian-and-ubuntu-tips/
│   │   ├── README.md
│   │   ├── auto-install/
│   │   │   ├── README.md
│   │   │   └── preseed-bookworm-ja_JP.txt
│   │   ├── debootstrap/
│   │   │   ├── README.md
│   │   │   ├── install-common.sh
│   │   │   ├── install-config-base.sh
│   │   │   ├── install-config-debian.sh
│   │   │   ├── install-config-ubuntu.sh
│   │   │   ├── install-mount.sh
│   │   │   ├── install1.sh
│   │   │   └── install2.sh
│   │   ├── initial-setup/
│   │   │   ├── README.md
│   │   │   ├── apt-sources.md
│   │   │   ├── btrfs.md
│   │   │   ├── cockpit.md
│   │   │   ├── desktop.md
│   │   │   ├── hardware.md
│   │   │   ├── network.md
│   │   │   └── ssh.md
│   │   ├── install-ubuntu-with-btrfs/
│   │   │   ├── README.md
│   │   │   ├── btrfs2-update.sh
│   │   │   ├── btrfs2.sh
│   │   │   ├── desktop.md
│   │   │   ├── server.md
│   │   │   ├── install.sh
│   │   │   ├── parted.sh
│   │   │   ├── update.sh
│   │   │   ├── desktop/
│   │   │   │   └── [23 image files]
│   │   │   ├── scripts/
│   │   │   │   ├── common.sh
│   │   │   │   ├── finalize.sh
│   │   │   │   └── initialize.sh
│   │   │   └── server/
│   │   │       └── [28 image files]
│   │   └── router/
│   │       ├── README.md
│   │       └── ufw.md
│   ├── rhel-tips/
│   │   └── README.md
│   └── windows-tips/
│       └── README.md
├── services/               # サービス・ミドルウェア
│   ├── authentication/     # 認証
│   │   ├── README.md
│   │   ├── freeipa/
│   │   │   ├── initial-settings.md
│   │   │   ├── install-client.md
│   │   │   ├── install-server-on-podman.md
│   │   │   └── install-server-on-rhel.md
│   │   ├── kanidm/
│   │   │   ├── README.md
│   │   │   ├── client-setup.md
│   │   │   ├── identity-setup.md
│   │   │   ├── initial-setup.md
│   │   │   ├── server-setup.md
│   │   │   └── ssh-jamp-server.md
│   │   └── step/
│   │       ├── client-setup.md
│   │       └── server-setup.md
│   ├── monitoring/         # 監視
│   │   ├── README.md
│   │   ├── dashboard.json
│   │   ├── grafana.md
│   │   ├── loki.md
│   │   ├── node-exporter.md
│   │   ├── promtail.md
│   │   └── victoriametrics.md
│   └── cloudflare-tunnel/  # ネットワークサービス
│       └── README.md
├── applications/           # アプリケーション実装例
│   └── flask-nginx/        # Flask + Nginx構成
│       └── README.md
├── development/            # 開発環境・ツール
│   ├── development-environment/
│   │   ├── README.md
│   │   └── mise/
│   │       ├── README.md
│   │       ├── configuration-management-tools.md
│   │       ├── miniforge-python.md
│   │       ├── nodejs.md
│   │       ├── opentofu.md
│   │       ├── pixi-python.md
│   │       ├── pnpm-nodejs.md
│   │       ├── rust.md
│   │       └── uv-python.md
│   └── github/
│       └── README.md
└── scripts/
    ├── freeipa
    ├── proxmox-ve
    ├── router
    └── update_or_add_textblock
```
