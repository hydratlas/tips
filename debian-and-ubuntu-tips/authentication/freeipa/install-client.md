# FreeIPAクライアントをインストール
## インストール
```sh
if hash apt-get 2>/dev/null; then
    sudo apt-get install --no-install-recommends -y freeipa-client
elif hash dnf 2>/dev/null; then
    sudo dnf install -y ipa-client
fi &&
eval "$(wget -q -O - "https://raw.githubusercontent.com/hydratlas/tips/refs/heads/main/scripts/freeipa")" &&
chosen_domain &&
sudo ipa-client-install --no-ntp --mkhomedir
#  --hostname="${domain}"
```

## サーバーへの接続を確認
adminアカウントのチケットを取得して、そのチケットを確認する。
```sh
kinit admin
klist
```
