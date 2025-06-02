# pve_vm_ssh_host_keys

Proxmox VE VM SSHホストキー管理ロール

## 概要

このロールは、Proxmox VE仮想マシンのSSHホストキーを管理します。virtiofs共有ストレージにホストキーを配置し、VMが再作成されても同じSSHホストキーを維持できるようにします。

## 要件

- Proxmox VE環境
- virtiofs共有ストレージ（`/mnt/host-ssh-keys`）
- rootまたはsudo権限

## ロール変数

- `ssh_host_key_name`: ホストキーファイル名のプレフィックス

## 使用例

```yaml
- hosts: pve_vms
  become: true
  vars:
    ssh_host_key_name: "{{ inventory_hostname }}"
  roles:
    - pve_vm_ssh_host_keys
```

## 設定内容

- virtiofs共有ストレージへのSSHホストキーのデプロイ
- VMのSSHホストキーの永続化
- VM再作成時のホストキー警告の防止