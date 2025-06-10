# pip_kubernetes

pipxを使用してkubernetes Pythonパッケージをインストールします。

## 説明

このロールは、pip（インストールされていない場合）をインストールし、その後kubernetes Pythonパッケージを独立した仮想環境にインストールします。Debian系およびRHEL系ディストリビューションをサポートしています。

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


## ライセンス

BSD

## 作成者情報

このロールはansible-homeプロジェクトのために作成されました。