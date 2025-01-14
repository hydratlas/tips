# Windows
## インストール
### VSCodium
```shell
winget install -e --id VSCodium.VSCodium
```
サイドバーのExtensionsアイコンから、「Japanese Language Pack」をインストールする。

## SSHクライアントキーの生成
```shell
$FILE = "$HOME/.ssh/id_rsa"
ssh-keygen -t rsa   -b 4096 -N '""' -C '""' -f "$FILE"
Get-Content "$FILE.pub"
$FILE = "$HOME/.ssh/id_ecdsa"
ssh-keygen -t ecdsa  -b 521 -N '""' -C '""' -f "$FILE"
Get-Content "$FILE.pub"
$FILE = "$HOME/.ssh/id_ed25519"
ssh-keygen -t ed25519       -N '""' -C '""' -f "$FILE"
Get-Content "$FILE.pub"
```
