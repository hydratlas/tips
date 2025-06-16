# pip_kubernetes

kubernetes Pythonパッケージをインストールします。

## 説明

このロールは、pip（インストールされていない場合）をインストールし、その後kubernetes Pythonパッケージをインストールします。Debian系およびRHEL系ディストリビューションをサポートしています。

## サポートOS

- Debian 12以降
- Ubuntu 24.04以降
- RHEL/CentOS/Rocky/Alma Linux 9以降

## 要件

- Ansible 2.9以降
- Python 3

## 依存関係

なし

## プレイブックの例

```yaml
- hosts: k3s_hosts
  roles:
    - pip_kubernetes
```

## 手動での設定手順

### Debian/Ubuntuでの設定

```bash
# パッケージリストの更新
sudo apt-get update

# python3-kubernetesパッケージのインストール
sudo apt-get install -y python3-kubernetes
```

### RHEL/CentOS/Rocky/Alma Linuxでの設定

```bash
# Python3 pipのインストール
sudo dnf install -y python3-pip

# kubernetes Pythonパッケージのインストール
sudo pip3 install kubernetes
```

### トラブルシューティング

#### 依存関係エラーの場合

```bash
# 必要な開発パッケージのインストール（Debian/Ubuntu）
sudo apt-get install -y python3-dev build-essential

# 必要な開発パッケージのインストール（RHEL系）
sudo dnf install -y python3-devel gcc
```

#### pipのアップグレード

```bash
# pipを最新版にアップグレード
pip3 install --upgrade pip
```

#### kubernetesパッケージのアップグレード

```bash
# pipでインストールした場合
pip3 install --upgrade kubernetes
```

### アンインストール

```bash
# pipでインストールした場合
pip3 uninstall kubernetes

# システムパッケージの場合（Debian/Ubuntu）
sudo apt-get remove python3-kubernetes
```

### 注意事項
- システムパッケージマネージャー（apt/dnf）とpipの混在使用は避けることを推奨します
- kubernetes Pythonパッケージは、Kubernetes APIとの通信に使用されます