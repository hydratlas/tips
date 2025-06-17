# podman_rootless_quadlet_base

Rootless Podman Quadletの共通セットアップを提供する基本ロール。他のロールから`include_tasks`で呼び出して使用します。

## 設定内容
- 専用のシステムユーザーを非特権ユーザーとして作成（subuid/subgidを自動割り当て）
- Lingering有効化してユーザーがログインしていなくてもサービスを実行可能に
- 必要なディレクトリ構造の作成
- ユーザーの`podman-auto-update.timer`を有効化し、コンテナイメージの自動更新を設定

## 変数

| 変数名 | 必須 | 説明 |
|--------|------|------|
| `quadlet_user` | ✓ | コンテナを実行するユーザー名 |
| `quadlet_app_name` | ✓ | アプリケーション名（設定ディレクトリ名に使用） |
| `quadlet_user_comment` | × | ユーザーコメント（デフォルト: "Rootless container user"） |
| `quadlet_user_shell` | × | ユーザーのシェル（デフォルト: "/usr/sbin/nologin"） |

## 設定される変数

このロールは以下の変数を設定します（呼び出し元で使用可能）：
- `quadlet_uid`: ユーザーのUID
- `quadlet_gid`: ユーザーのGID
- `quadlet_home`: ユーザーのホームディレクトリ
- `quadlet_config_dir`: アプリケーション設定ディレクトリ (`~/.config/{app_name}`)
- `quadlet_systemd_dir`: Quadletファイル配置ディレクトリ (`~/.config/containers/systemd`)

## 使用例

```yaml
# 他のロールのtasks/main.ymlから呼び出す例
---
- name: Include common Rootless Podman Quadlet setup
  ansible.builtin.include_tasks: ../../podman_rootless_quadlet_base/tasks/main.yml
  vars:
    quadlet_user: "myapp"
    quadlet_user_comment: "My Application rootless user"
    quadlet_app_name: "myapp"

- name: Set app specific facts
  ansible.builtin.set_fact:
    myapp_uid: "{{ quadlet_uid }}"
    myapp_home: "{{ quadlet_home }}"
    myapp_config_dir: "{{ quadlet_config_dir }}"
    myapp_systemd_dir: "{{ quadlet_systemd_dir }}"

# 以降、アプリケーション固有の設定を続ける
```

## 作成されるディレクトリ

- `{home}/` - ユーザーのホームディレクトリ
- `{home}/.config/` - 設定ディレクトリ
- `{home}/.config/{app_name}/` - アプリケーション固有の設定
- `{home}/.config/containers/systemd/` - Quadletファイル配置場所
- `{home}/.local/share/containers/storage/` - コンテナストレージ

## トラブルシューティング
### systemd関係コマンド
```bash
# アプリケーション名とユーザー名を設定
APP_NAME="myapp"
QUADLET_USER="myapp"

# サービスの状態確認
sudo -u ${QUADLET_USER} XDG_RUNTIME_DIR="/run/user/$(id -u ${QUADLET_USER})" systemctl --user status "${APP_NAME}.service"

# サービスの再起動
sudo -u ${QUADLET_USER} XDG_RUNTIME_DIR="/run/user/$(id -u ${QUADLET_USER})" systemctl --user restart "${APP_NAME}.service"

# サービスのログの確認（最新の100行）
sudo -u ${QUADLET_USER} journalctl --user -u "${APP_NAME}.service" --no-pager -n 100

# サービスのログの確認（リアルタイム表示）
sudo -u ${QUADLET_USER} journalctl --user -u "${APP_NAME}.service" -f

# 自動更新タイマーの状態確認
sudo -u ${QUADLET_USER} XDG_RUNTIME_DIR="/run/user/$(id -u ${QUADLET_USER})" systemctl --user status podman-auto-update.timer
```

### podman関係コマンド
```bash
# アプリケーション名とユーザー名を設定
APP_NAME="myapp"
QUADLET_USER="myapp"

# コンテナの状態確認
sudo -u ${QUADLET_USER} podman ps
```

### 設定の確認
```bash
# subuid/subgidの確認
grep ${QUADLET_USER} /etc/subuid /etc/subgid

# lingeringの確認
loginctl show-user ${QUADLET_USER} --property=Linger
```

### 停止・削除
```bash
# サービスの停止
sudo -u ${QUADLET_USER} XDG_RUNTIME_DIR=/run/user/$(id -u ${QUADLET_USER}) systemctl --user stop ${APP_NAME}.service

# Quadletコンテナ定義ファイルの削除
sudo rm "/home/${QUADLET_USER}/.config/containers/systemd/${APP_NAME}.container"

# systemdユーザーデーモンのリロード
sudo -u ${QUADLET_USER} XDG_RUNTIME_DIR=/run/user/$(id -u ${QUADLET_USER}) systemctl --user daemon-reload

## lingeringを無効化
sudo loginctl disable-linger ${QUADLET_USER}
```

## 手動での設定手順

以下の手順により、Rootless Podman Quadletを手動で設定できます：

### 1. 準備
#### 専用ユーザーの作成

システムユーザーを作成し、ルートレスコンテナ用のsubuid/subgidを割り当てます：

```bash
# アプリケーション名とユーザー名を設定
APP_NAME="myapp"
QUADLET_USER="myapp"
USER_COMMENT="My Application rootless user"

# ユーザーの作成（subuid/subgid付き）
USER_SHELL="/usr/sbin/nologin"  # 必要に応じて変更可能
sudo useradd --system --user-group --add-subids-for-system --shell ${USER_SHELL} --comment "${USER_COMMENT}" ${QUADLET_USER}

# systemd-journalグループへの追加
sudo usermod -aG systemd-journal ${QUADLET_USER}

# ユーザーのホームディレクトリーの取得
QUADLET_HOME=$(getent passwd ${QUADLET_USER} | cut -d: -f6)
```

#### systemd lingeringの有効化

ユーザーがログインしていなくてもサービスを実行できるようにします：

```bash
# lingeringを有効化
sudo loginctl enable-linger ${QUADLET_USER}
```

#### 必要なディレクトリ構造の作成

Quadletとコンテナストレージ用のディレクトリを作成します：

```bash
# 必要なディレクトリを作成
sudo mkdir -p ${QUADLET_HOME}/.config/${APP_NAME} &&
sudo mkdir -p ${QUADLET_HOME}/.config/containers/systemd &&
sudo mkdir -p ${QUADLET_HOME}/.local/share/containers/storage

# 所有権の設定
sudo chown -R ${QUADLET_USER}:${QUADLET_USER} ${QUADLET_HOME}

# パーミッションの設定
sudo chmod -R 755 ${QUADLET_HOME}
```

### 2. Quadletファイルなどの配置

以下を行います：

1. アプリケーション固有の設定ファイルを`${QUADLET_HOME}/.config/${APP_NAME}`に配置
2. Quadletファイル（.container、.volume、.network）を`${QUADLET_HOME}/.config/containers/systemd`に配置

### 3. サービスおよびタイマーの起動と有効化
#### Quadletサービスの起動

ユーザーのsystemdデーモンをリロードします：

```bash
# systemdユーザーデーモンのリロード
sudo -u ${QUADLET_USER} XDG_RUNTIME_DIR="/run/user/$(id -u ${QUADLET_USER})" systemctl --user daemon-reload

# サービスの起動
sudo -u ${QUADLET_USER} XDG_RUNTIME_DIR="/run/user/$(id -u ${QUADLET_USER})" systemctl --user start "${APP_NAME}.service"
```

#### podman-auto-update.timerの起動と有効化

コンテナイメージの自動更新を有効にします：

```bash
# タイマーの起動と有効化
sudo -u ${QUADLET_USER} XDG_RUNTIME_DIR="/run/user/$(id -u ${QUADLET_USER})" systemctl --user enable --now podman-auto-update.timer
```
