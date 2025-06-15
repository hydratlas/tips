## このドキュメントサイト自体の説明

このドキュメントサイトは[MkDocs](https://www.mkdocs.org/)と[Material for MkDocs](https://squidfunk.github.io/mkdocs-material/)を使用して構築されています。依存関係の管理には[uv](https://docs.astral.sh/uv/)を使用しています。

### ローカル環境でのセットアップ

1. uvのインストール（まだインストールしていない場合）
   ```bash
   curl -LsSf https://astral.sh/uv/install.sh | sh
   ```

2. 依存関係のインストール
   ```bash
   uv sync
   ```

3. ローカルサーバーの起動（開発用）
   ```bash
   uv run mkdocs serve
   ```
   http://127.0.0.1:8000/ でプレビューできます。

4. サイトのビルド（本番用）
   ```bash
   uv run mkdocs build
   ```
   `site/`ディレクトリに静的HTMLが生成されます。

5. 依存関係のアップデート
   ```bash
   uv lock --upgrade &&
   uv sync
   ```
