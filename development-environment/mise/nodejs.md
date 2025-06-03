# mise & Node.js
## プロジェクトディレクトリーの作成
```sh
mkdir ~/nodejs_test_project &&
cd ~/nodejs_test_project
```

## ランタイムおよびツールのインストール
プロジェクトローカルにNode.jsランタイムおよびパッケージ管理ツールをインストールする。Node.jsはパッケージ管理ツールを、Node.js付属のnpm、Yarnおよびpnpmから選択できる。選択に応じてYarnまたはpnpmをインストールする。インストールした内容は設定ファイル(.mise.toml)に記録される。

### Node.js
```sh
mise use -y node@24 &&
echo "node: $(node --version)" &&
echo "npm: $(node --version)"
```
`mise ls-remote node`コマンドでインストール可能なバージョンがリストアップされる。

### Yarn
```sh
mise use -y yarn@4 &&
yarn --version &&
```
`mise ls-remote yarn`コマンドでインストール可能なバージョンがリストアップされる。

### pnpm
```sh
mise use -y pnpm@10 &&
pnpm --version
```
`mise ls-remote -y pnpm`コマンドでインストール可能なバージョンがリストアップされる。

## ランタイムおよびツールの再インストール
設定ファイル(.mise.toml)からランタイムおよびツールを再インストールする場合。
```sh
mise install -y
```

## プロジェクトの初期化およびパッケージのインストール
### npm（Node.js付属）
```sh
npm init -y &&
npm install cowsay &&
npm ls
```

### Yarn
```sh
yarn init -y &&
yarn add cowsay &&
yarn list
```

### pnpm
```sh
pnpm init &&
pnpm add cowsay &&
pnpm list
```

## パッケージデータの削除
インストールされたパッケージのデータのデータの削除する。どのパッケージがインストールされていたのかを記録した設定ファイル（package.jsonなど）は残るため、削除しても再インストールすることができる。
```sh
rm -rf node_modules
```

## パッケージデータの再インストール
設定ファイル（package.jsonなど）からインストールされたパッケージのデータを再インストールする。

### npm（Node.js付属）
```sh
npm install
```

### Yarn
```sh
yarn install
```

### pnpm
```sh
pnpm install
```

## ツールのアンインストール
`.mise.toml`を参照しているため、プロジェクトディレクトリーのルートで実行する必要がある。

### Node.js
```sh
mise uninstall node &&
perl -pi -e "s/^node = \".+\"\\n//mg" .mise.toml
```

### Yarn
```sh
mise uninstall yarn &&
perl -pi -e "s/^yarn = \".+\"\\n//mg" .mise.toml
```

### pnpm
```sh
mise uninstall pnpm &&
mise plugins uninstall -y pnpm &&
perl -pi -e "s/^pnpm = \".+\"\\n//mg" .mise.toml
```
