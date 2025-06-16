# podman_auto_update

Podmanコンテナの自動更新を有効化するAnsibleロール。

## 概要

このロールは、Podmanの自動更新機能を有効化します。`AutoUpdate=registry`ラベルが設定されたコンテナのイメージを定期的にチェックし、新しいバージョンがある場合は自動的に更新・再起動します。

## 前提条件

- Podmanがインストールされていること
- systemdがインストールされていること

## 設定内容

- `podman-auto-update.timer`を有効化して起動
- デフォルトでは毎日深夜（00:00）に更新チェックを実行

## 使用例

```yaml
- hosts: container_hosts
  roles:
    - role: podman_auto_update
```

## コンテナ側の設定

自動更新を有効にするには、コンテナに以下のラベルを設定する必要があります：

### Podman Quadletの場合
```ini
[Container]
AutoUpdate=registry
```

### docker-compose.ymlの場合
```yaml
services:
  myapp:
    labels:
      - "io.containers.autoupdate=registry"
```

### podman runの場合
```bash
podman run --label io.containers.autoupdate=registry ...
```

## トラブルシューティング

```bash
# タイマーの状態確認
systemctl status podman-auto-update.timer

# 手動で更新を実行
systemctl start podman-auto-update.service

# 更新ログの確認
journalctl -u podman-auto-update.service

# 次回の実行予定時刻を確認
systemctl list-timers podman-auto-update.timer
```

## 注意事項

- 自動更新は`registry`タイプのみサポート（ローカルイメージの更新は対象外）
- 更新時はコンテナが一時的に停止・再起動されるため、ダウンタイムが発生
- 更新に失敗した場合は、古いイメージでコンテナが再起動される