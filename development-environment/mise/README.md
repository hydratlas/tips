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
#if [ -e ~/.local/share/mise/shims ]; then
#  export PATH="\$HOME/.local/share/mise/shims:\$PATH"
#fi
EOS
) &&
if ! grep -q "$START_MARKER" "$TARGET_FILE"; then
  echo -e "$START_MARKER\n$CODE_BLOCK\n$END_MARKER" | tee -a "$TARGET_FILE" > /dev/null  
fi &&
. "$TARGET_FILE" &&
mise --version
```
- [Getting Started | mise-en-place](https://mise.jdx.dev/getting-started.html)

## 基本的なツールのインストール
```sh
mise use -g jq
```

## シェル補完のインストール（bashの場合）
```sh
mise use -g usage &&
mkdir -p ~/.local/share/bash-completion/completions &&
tee ~/.local/share/bash-completion/completions/mise << EOS > /dev/null &&
if hash mise 2>/dev/null; then
  eval "\$(mise completion bash --include-bash-completion-lib)"
fi
EOS
. ~/.local/share/bash-completion/completions/mise
```
- [Not generating mise completions despite usage CLI is installed · Issue #1710 · jdx/mise](https://github.com/jdx/mise/issues/1710)

## 状態確認
```sh
mise doctor
```

## 使用
miseでユーザーグローバルにツールをインストールして、そのツールで各プロジェクトのプログラミング言語のバージョンを管理する場合と、miseで直接各プロジェクトのプログラミング言語のバージョンを管理する場合がある。後者のほうがmise本来の使い方であるが、前者のほうがシェル補完がききやすく、使いやすい。
- ユーザーグローバル
  - [Node.js & pnpm](pnpm-nodejs.md)
      - 各プロジェクト
          - Node.js & pnpm
  - [uv](uv-python.md) (Pip)
      - 各プロジェクト
          - Python
  - [pixi](pixi-python.md) (Conda): mambaを作っているprefix.devが作っている、Rust言語に基づく高速なパッケージ管理システム（おすすめ）
      - 各プロジェクト
          - Python
  - Python ([Miniforge](mise/miniforge-python.md) (Conda)): conda-forgeリポジトリで作っているパッケージ管理システム
      - 各プロジェクト
          - Python
  - [Rust & Cargo](rust.md)
- 各プロジェクト
  - [Node.js](nodejs.md)
      - Node.js & npm（Node.js付属）
      - Node.js & Yarn
      - Node.js & pnpm

## アップデート
```sh
mise self-update --no-plugins &&
mise plugins update &&
mise upgrade
```
それぞれmise本体、プラグインおよびツールをアップデートする。

## キャッシュの削除
```sh
mise cache clear
```

## シェル補完のアンインストール（bashの場合）
```sh
if [ -f ~/.local/share/bash-completion/completions/mise ]; then
  rm ~/.local/share/bash-completion/completions/mise
fi
```

## アンインストール（bashの場合）
```sh
mise implode -y
```
アンインストール後にシェルに`-bash: /home/<username>/.local/bin/mise: No such file or directory`とエラーメッセージが表示されるようになるが、シェルを開き直せば解消される。

## 各種ツールによるシェル補完のアンインストール（bashの場合）
```sh
TARGET_FILE="$HOME/.bashrc" &&
START_MARKER="# BEGIN MISE BLOCK" &&
END_MARKER="# END MISE BLOCK" &&
if grep -q "$START_MARKER" "$TARGET_FILE"; then
  sed -i "/$START_MARKER/,/$END_MARKER/d" "$TARGET_FILE"
fi &&
if [ -d "$HOME/.local/share/bash-completion/completions" ]; then
  find "$HOME/.local/share/bash-completion/completions" -type f -iname 'mise-*' -exec rm {} +
fi
```

## ユーザーグローバルにインストールしたツールやシステムの再インストール
設定ファイル(~/.config/mise/config.toml)からユーザーグローバルにインストールしたツールやシステムを再インストールする。プラグインは手動でのインストールが必要になる場合がある。
```sh
mise install -y
```
