# Windows
## SSHクライアントキーの生成
```shell
$FILE = "$HOME/.ssh/id_rsa"
ssh-keygen -t rsa   -b 4096 -N '' -C '' -f "$FILE"
Set-Content -Path "$FILE.pub" -Value (Get-Content "$FILE.pub" | ForEach-Object { $_ -replace '\s+\S+$', '' })
$FILE = "$HOME/.ssh/id_ecdsa"
ssh-keygen -t ecdsa  -b 521 -N '' -C '' -f "$FILE"
Set-Content -Path "$FILE.pub" -Value (Get-Content "$FILE.pub" | ForEach-Object { $_ -replace '\s+\S+$', '' })
$FILE = "$HOME/.ssh/id_ed25519"
ssh-keygen -t ed25519       -N '' -C '' -f "$FILE"
Set-Content -Path "$FILE.pub" -Value (Get-Content "$FILE.pub" | ForEach-Object { $_ -replace '\s+\S+$', '' })
```
