# 構成管理ツール
## Linux（Bash + mise + uv）
### Terraformのインストール
```sh
mise use terraform
```

### Ansibleのインストール
```sh
uv init &&
uv python pin 3.13 &&
uv add ansible
```

## Windows（Git Bash）
### Terraformのインストール
```sh
winget install -e --id Hashicorp.Terraform
```

### uvのインストール
```sh
winget install -e --id astral-sh.uv
```

### Ansibleのインストール
```sh
uv init &&
uv python pin 3.13 &&
uv add ansible
```

### Ansibleの再インストール
`pyproject.toml`にもとづいて再インストールします。
```sh
uv sync
```
