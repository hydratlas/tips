# Rust & Cargo
## ユーザーグローバルでの設定
### インストール
```sh
mise use -g -y rust &&
"$(mise which rustc)" --version
```

### シェル補完のインストール（bashの場合）
```sh
mkdir -p "$HOME/.local/share/bash-completion/completions" &&
tee "$HOME/.local/share/bash-completion/completions/rustup" <<- EOS > /dev/null &&
if hash rustup 2>/dev/null; then
  eval "\$(rustup completions bash)"
fi
EOS
. "$HOME/.local/share/bash-completion/completions/rustup"
CREATE_COMPLETION () {
  tee "$HOME/.local/share/bash-completion/completions/$1" <<- EOS > /dev/null
  if hash rustup 2>/dev/null && hash $1 2>/dev/null; then
    eval "\$(rustup completions bash $1)"
  fi
EOS
}
CREATE_COMPLETION "cargo" &&
CREATE_COMPLETION "rustc" &&
CREATE_COMPLETION "rustfmt"
```

### シェル補完のアンインストール（bashの場合）
```sh
DELETE_COMPLETION () {
  if [ -e "$HOME/.local/share/bash-completion/completions/$1" ]; then
    rm "$HOME/.local/share/bash-completion/completions/$1"
  fi
}
DELETE_COMPLETION "rustup" &&
DELETE_COMPLETION "cargo" &&
DELETE_COMPLETION "rustc" &&
DELETE_COMPLETION "rustfmt"
```

### アンインストール
```sh
mise uninstall rust &&
perl -p -i -e "s/^rust = \".+\"\\n//mg" ~/.config/mise/config.toml
```
