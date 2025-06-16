
# QEMUゲストエージェントをインストールする
QEMU（仮想マシン）で、仮想マシンのゲストの場合にはインストールする。
```bash
sudo apt-get install --no-install-recommends -y qemu-guest-agent
```

# デスクトップ環境でクリップボード共有をする
```bash
sudo apt-get install --no-install-recommends -y spice-vdagent
```
インストール後、SPICEクライアントで接続する。Debian系なら`sudo apt-get install -y remmina-plugin-spice remmina-plugin-exec`でRemmina本体とSPICEプラグインがインストールされる（しかしこの方法はうまくいかない）。