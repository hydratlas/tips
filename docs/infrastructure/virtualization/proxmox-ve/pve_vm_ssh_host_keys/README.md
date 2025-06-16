# pve_vm_ssh_host_keys

Proxmox VE VM SSHホストキー管理ロール

## 概要

このロールは、Proxmox VE仮想マシンのSSHホストキーを管理します。virtiofs共有ストレージにホストキーを配置し、VMが再作成されても同じSSHホストキーを維持できるようにします。

## 要件

- Proxmox VE環境
- virtiofs共有ストレージ（`/mnt/host-ssh-keys`）
- rootまたはsudo権限
- プレイブックレベルで`become: true`の指定が必要

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

## 手動での設定手順

以下の手順でProxmox VEホストからVMのSSHホストキーを手動で管理できます：

### 1. SSHホストキーの生成（初回のみ）

```bash
# 新しいSSHホストキーペアを生成
ssh-keygen -t ed25519 -f /tmp/ssh_host_ed25519_key -N '' -C ''

# 生成されたキーを確認
ls -la /tmp/ssh_host_ed25519_key*
```

### 2. virtiofs共有ディレクトリの作成

```bash
# VM IDを設定（例：100）
VMID=100

# virtiofs共有ディレクトリを作成
mkdir -p /mnt/pve/virtiofs-share/${VMID}/ssh_host_key
chmod 700 /mnt/pve/virtiofs-share/${VMID}/ssh_host_key
```

### 3. SSHホストキーの配置

```bash
# 秘密鍵をコピー
cp /tmp/ssh_host_ed25519_key /mnt/pve/virtiofs-share/${VMID}/ssh_host_key/
chmod 600 /mnt/pve/virtiofs-share/${VMID}/ssh_host_key/ssh_host_ed25519_key

# 公開鍵をコピー
cp /tmp/ssh_host_ed25519_key.pub /mnt/pve/virtiofs-share/${VMID}/ssh_host_key/
chmod 644 /mnt/pve/virtiofs-share/${VMID}/ssh_host_key/ssh_host_ed25519_key.pub

# 所有者を設定
chown -R root:root /mnt/pve/virtiofs-share/${VMID}/ssh_host_key/
```

### 4. VM側での設定（VM内で実行）

```bash
# virtiofs共有をマウント（通常はcloud-initで自動設定）
mount -t virtiofs host-ssh-keys /mnt/host-ssh-keys

# 既存のSSHホストキーをバックアップ
mkdir -p /etc/ssh/backup
mv /etc/ssh/ssh_host_* /etc/ssh/backup/ 2>/dev/null || true

# virtiofs共有からSSHホストキーをコピー
cp /mnt/host-ssh-keys/ssh_host_ed25519_key /etc/ssh/
cp /mnt/host-ssh-keys/ssh_host_ed25519_key.pub /etc/ssh/
chmod 600 /etc/ssh/ssh_host_ed25519_key
chmod 644 /etc/ssh/ssh_host_ed25519_key.pub

# SSHサービスを再起動
systemctl restart ssh
```

### 5. 設定の確認

```bash
# Proxmox VEホスト側で確認
ls -la /mnt/pve/virtiofs-share/${VMID}/ssh_host_key/

# VM側で確認
ssh-keygen -lf /etc/ssh/ssh_host_ed25519_key.pub

# 別のホストから接続してホストキーが変わらないことを確認
ssh -o StrictHostKeyChecking=ask vm-hostname
```

### 複数のVMに対する一括設定

```bash
# VM IDのリストを定義
VM_IDS="100 101 102"

# 各VMに対してディレクトリ作成とキー配置を実行
for VMID in $VM_IDS; do
    echo "Setting up SSH host keys for VM ${VMID}..."
    
    # ディレクトリ作成
    mkdir -p /mnt/pve/virtiofs-share/${VMID}/ssh_host_key
    chmod 700 /mnt/pve/virtiofs-share/${VMID}/ssh_host_key
    
    # キーを生成して配置（各VMで異なるキーを使用する場合）
    ssh-keygen -t ed25519 -f /tmp/ssh_host_ed25519_key_${VMID} -N '' -C ''
    cp /tmp/ssh_host_ed25519_key_${VMID} /mnt/pve/virtiofs-share/${VMID}/ssh_host_key/ssh_host_ed25519_key
    cp /tmp/ssh_host_ed25519_key_${VMID}.pub /mnt/pve/virtiofs-share/${VMID}/ssh_host_key/ssh_host_ed25519_key.pub
    
    # パーミッション設定
    chmod 600 /mnt/pve/virtiofs-share/${VMID}/ssh_host_key/ssh_host_ed25519_key
    chmod 644 /mnt/pve/virtiofs-share/${VMID}/ssh_host_key/ssh_host_ed25519_key.pub
    chown -R root:root /mnt/pve/virtiofs-share/${VMID}/ssh_host_key/
    
    # 一時ファイルを削除
    rm -f /tmp/ssh_host_ed25519_key_${VMID}*
done
```

注意事項：
- virtiofs共有は事前に設定されている必要があります
- VMのcloud-init設定でvirtiofs共有のマウントとSSHホストキーのコピーを自動化することを推奨します
- セキュリティのため、各VMには異なるSSHホストキーを使用してください
- 秘密鍵のパーミッションは600、公開鍵は644に設定してください