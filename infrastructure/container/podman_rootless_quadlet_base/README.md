# podman_rootless_quadlet_base

Rootless Podman Quadletの共通セットアップを提供する基本ロール。他のロールから`include_tasks`で呼び出して使用します。

## 概要

このロールは、Rootless Podman Quadletでコンテナを実行するための共通タスクを提供します：
- 専用ユーザーの作成（subuid/subgid付き）
- 必要なディレクトリ構造の作成
- systemd lingeringの有効化
- podman-auto-update.timerの有効化

## 変数

| 変数名 | 必須 | 説明 |
|--------|------|------|
| `quadlet_user` | ✓ | コンテナを実行するユーザー名 |
| `quadlet_app_name` | ✓ | アプリケーション名（設定ディレクトリ名に使用） |
| `quadlet_user_comment` | × | ユーザーコメント（デフォルト: "Rootless container user"） |

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

## 機能

1. **ユーザー作成**: システムユーザーとして作成し、subuid/subgidを自動割り当て
2. **Lingering有効化**: ユーザーがログインしていなくてもサービスを実行可能に
3. **自動更新**: podman-auto-update.timerによるコンテナイメージの自動更新
4. **systemdリロード**: ユーザースコープでのsystemdデーモンリロード