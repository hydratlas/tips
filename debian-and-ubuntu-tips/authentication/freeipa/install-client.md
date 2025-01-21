# FreeIPAクライアントをインストール
## インストール
```sh
if hash apt-get 2>/dev/null; then
    sudo apt-get install --no-install-recommends -y freeipa-client
elif hash dnf 2>/dev/null; then
    sudo dnf install -y ipa-client
fi &&
search_line=$(grep '^search ' /etc/resolv.conf 2>/dev/null)
if [ -z "${search_line}" ]; then
  echo "ERROR: No search line was found in /etc/resolv.conf."
else
  domains_str="${search_line#search }" &&
  IFS=' ' read -ra domeins <<< "${domains_str}" &&
  echo "Please select a number from the following domains:" &&
  count=1 &&
  for domain in "${domeins[@]}"; do
    echo "  ${count}) $(hostname -s).${domain}" &&
    ((count++))
  done
  read -p "Please enter the number: " choice &&
  if [[ ${choice} =~ ^[0-9]+$ ]] && [ ${choice} -ge 1 ] && [ ${choice} -le ${#domeins[@]} ]; then
    chosen_domain="$(hostname -s).${domeins[$((choice-1))]}" &&
    echo "Selected domain: ${chosen_domain}" &&
    sudo ipa-client-install --hostname="${chosen_domain}" --no-ntp --mkhomedir
  else
    echo "An invalid number was entered."
  fi
fi
```

## サーバーへの接続を確認
adminアカウントのチケットを取得して、そのチケットを確認する。
```sh
kinit admin
klist
```
