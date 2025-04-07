# OpenTofu
```sh
mise use aqua:opentofu/opentofu
tofu version
tofu validate
```

プロバイダーのインストールは、`.tf`ファイルにプロバイダーを記述した上で`tofu init`コマンドを実行する。バージョンを変更した場合には`tofu init -upgrade`コマンドを実行する。