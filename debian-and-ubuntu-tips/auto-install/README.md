# 自動インストール
## Debian
1. netinst.isoから起動
1. 「install」にフォーカスを当てて、「e」キーを押す（「Graphical install」ではない）
1. `linux /install.amd/vmlinuz`の直後に次を挿入
  - ` auto=true priority=critical url=https://raw.githubusercontent.com/hydratlas/tips/refs/heads/main/debian-and-ubuntu-tips/auto-install/preseed-bookworm-ja_JP.txt hostname=test `
1. 「F10」キーを押してインストーラーを起動させる