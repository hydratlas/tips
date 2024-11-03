# mise & uv & Python
## ユーザーグローバルでの設定
### インストール
```sh
mise use -g -y uv &&
mise settings set pipx_uvx true &&
"$(mise which uv)" --version
```
uvのインストールとともに、uvxが存在する場合にはpipxの代わりにuvxを使うようにしている。pipxはPythonでできているコマンドラインツールを個別の環境に分離してインストールするもの。pipでは環境を分離しないため依存関係が破壊される可能性があるが、環境の分離によってそれを防ぐ。pipおよびuvは主に実行したいPythonコードから依存するライブラリーのインストールに使用するが、pipxおよびuvxはコマンドラインツールのインストールに使用する。

### シェル補完のインストール（bashの場合）
```sh
mkdir -p ~/.local/share/bash-completion/completions &&
tee ~/.local/share/bash-completion/completions/mise-uv << EOS > /dev/null &&
if hash mise 2>/dev/null && mise which uv 2>/dev/null; then
  eval "\$(uv generate-shell-completion bash)"
fi
EOS
tee ~/.local/share/bash-completion/completions/mise-uvx << EOS > /dev/null &&
if hash mise 2>/dev/null && mise which uvx 2>/dev/null; then
  eval "\$(uvx --generate-shell-completion bash)"
fi
EOS
. ~/.local/share/bash-completion/completions/mise-uv &&
. ~/.local/share/bash-completion/completions/mise-uvx
```

### シェル補完のアンインストール（bashの場合）
```sh
if [ -e ~/.local/share/bash-completion/completions/mise-uv ]; then
  rm ~/.local/share/bash-completion/completions/mise-uv
fi &&
if [ -e ~/.local/share/bash-completion/completions/mise-uvx ]; then
  rm ~/.local/share/bash-completion/completions/mise-uvx
fi
```

### アンインストール
```sh
mise settings unset pipx_uvx &&
mise uninstall uv &&
perl -p -i -e "s/^uv = \".+\"\\n//mg" ~/.config/mise/config.toml
```
`mise use`を元に戻すサブコマンドは2024年11月現在、存在しない（参照：[`mise rm` · Issue #1465 · jdx/mise](https://github.com/jdx/mise/issues/1465)）。

## プロジェクトでの使用
### プロジェクトの作成
```sh
mkdir ~/uv_test_project &&
cd ~/uv_test_project &&
uv init
```

### Pythonのインストール
```sh
uv python pin 3.13 &&
uv run python3 --version
```
`uv python list`コマンドでインストール可能なバージョンがリストアップされる。

### Pythonライブラリーのインストール
```sh
uv add cowsay &&
uv pip list &&
uv run cowsay -t "Hello, world!"
```

### 環境の再構築
設定ファイルから環境を再構築する場合。
```sh
cd ~/uv_test_project &&
uv sync
```
