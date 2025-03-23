# 開発環境
## システムグローバル
### Debian系
```sh
sudo apt-get install -y git
```

### RHEL系
```sh
sudo dnf install -y git
```

### Windows
```powershell
winget install -e --id Git.Git
$env:Path = [System.Environment]::GetEnvironmentVariable( `
  'Path', [System.EnvironmentVariableTarget]::Machine) # インストール直後にGitをすぐ使えるように、システムレベルのPath環境変数を現在のPowerShellセッションに反映
```
