# OpenTofu
```sh
mise use aqua:opentofu/opentofu
tofu version
tofu init
tofu init -upgrade
tofu validate
tofu plan
tofu apply
TF_LOG=DEBUG tofu apply -auto-approve
```

プロバイダーのインストールは、`.tf`ファイルにプロバイダーを記述した上で`tofu init`コマンドを実行する。バージョンを変更した場合には`tofu init -upgrade`コマンドを実行する。