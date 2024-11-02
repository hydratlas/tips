# mise（プログラミング言語のバージョン管理）
## インストール（bashの場合）
```sh
wget -q -O - https://mise.run | sh &&
~/.local/bin/mise --version &&
~/.local/bin/mise reshim &&
TARGET_FILE="$HOME/.bashrc" &&
START_MARKER="# BEGIN MISE BLOCK" &&
END_MARKER="# END MISE BLOCK" &&
CODE_BLOCK=$(cat << EOS
if [ -e ~/.local/bin/mise ]; then
  eval "\$(~/.local/bin/mise activate bash)"
fi
if [ -e ~/.local/share/mise/shims ]; then
  export PATH="\$HOME/.local/share/mise/shims:\$PATH"
fi
EOS
) &&
if ! grep -q "$START_MARKER" "$TARGET_FILE"; then
  echo -e "$START_MARKER\n$CODE_BLOCK\n$END_MARKER" | tee -a "$TARGET_FILE" > /dev/null &&
  . "$TARGET_FILE"
fi &&
mise --version
```
- [Getting Started | mise-en-place](https://mise.jdx.dev/getting-started.html)

## シェル補完の有効化（bashの場合）
```sh
mise use -g usage &&
mkdir -p ~/.local/share/bash-completion/completions &&
tee ~/.local/share/bash-completion/completions/mise <<< "$(mise completion bash)" > /dev/null &&
. ~/.local/share/bash-completion/completions/mise
```
- [Not generating mise completions despite usage CLI is installed · Issue #1710 · jdx/mise](https://github.com/jdx/mise/issues/1710)

## 状態確認
```sh
mise doctor
```

## 使用
- Python
  - Pip
    - [uv](python-uv.md)
  - Conda
    - [pixi](python-pixi.md): mambaを作っているprefix.devが作っている、Rust言語に基づく高速なパッケージ管理システム
    - [Miniforge](python-miniforge.md): conda-forgeリポジトリで作っているパッケージ管理システム

## アップデート
```sh
mise self-update --no-plugins &&
mise plugins update &&
mise upgrade
```
それぞれmise本体、プラグインおよびツールをアップデートする。

## シェル補完の無効化（bashの場合）
```sh
if [ -f ~/.local/share/bash-completion/completions/mise ]; then
  rm ~/.local/share/bash-completion/completions/mise
fi
```

## アンインストール（bashの場合）
```sh
TARGET_FILE="$HOME/.bashrc" &&
START_MARKER="# BEGIN MISE BLOCK" &&
END_MARKER="# END MISE BLOCK" &&
if grep -q "$START_MARKER" "$TARGET_FILE"; then
  sed -i "/$START_MARKER/,/$END_MARKER/d" "$TARGET_FILE"
fi &&
if [ -d "$HOME/.local/share/bash-completion/completions" ]; then
  find "$HOME/.local/share/bash-completion/completions" -type f -iname 'mise-*' -exec rm {} +
fi &&
mise implode -y
```
アンインストール後にシェルに`-bash: /home/<username>/.local/bin/mise: No such file or directory`とエラーメッセージが表示されるようになるが、シェルを開き直せば解消される。
