# Flask + uWSGI + nginxのセットアップ
Ubuntu 24.04を前提とする。頻出する`myproject`は仮の値。
- 参考：
  - [UbuntuにAnaconda+Flask環境を作成する #Python - Qiita](https://qiita.com/katsujitakeda/items/b8e0cdc04611e3645f76#nginx%E3%81%AE%E8%A8%AD%E5%AE%9A)
  - [How To Serve Flask Applications with uWSGI and Nginx on Ubuntu 22.04 | DigitalOcean](https://www.digitalocean.com/community/tutorials/how-to-serve-flask-applications-with-uwsgi-and-nginx-on-ubuntu-22-04#step-6-configuring-nginx-to-proxy-requests)

## nginxのインストール
```sh
sudo apt-get install -y --no-install-recommends nginx &&
sudo systemctl enable --now nginx.service
```

## Minicondaのインストール
```sh
sudo apt-get install -y --no-install-recommends wget ca-certificates &&
wget --quiet -O miniconda.sh https://repo.anaconda.com/miniconda/Miniconda3-py312_24.7.1-0-Linux-x86_64.sh &&
bash miniconda.sh -b -p "$HOME/miniconda3" &&
rm miniconda.sh &&
"$HOME/miniconda3/bin/conda" init &&
tee -a "$HOME/.bashrc" <<- EOS > /dev/null &&
export PATH=$HOME/miniconda3/bin:\$PATH
EOS
source "$HOME/.bashrc" &&
conda -V
```

## 仮想環境の作成とFlaskおよびuWSGIのインストール
```sh
conda create -p "$HOME/miniconda3/envs/myproject" -y &&
conda activate "$HOME/miniconda3/envs/myproject" &&
conda install python=3.11 flask=3.0.3 uwsgi=2.0.21 -y &&
conda deactivate
```

## Flaskのデータの作成
```sh
mkdir "$HOME/myproject" &&
tee "$HOME/myproject/myproject.py" <<- 'EOS' > /dev/null
from flask import Flask

app = Flask(__name__)

@app.route("/")
def hello_world():
    return "<p>Hello, World!</p>"

if __name__ == "__main__":
    app.run(host='0.0.0.0')
EOS
```

## Flaskのテスト
```sh
conda activate "$HOME/miniconda3/envs/myproject" &&
python "$HOME/myproject/myproject.py"
```

http://your_server_ip:5000にアクセスする。

```sh
conda deactivate
```

## uWSGIのデータの作成
```sh
tee "$HOME/myproject/wsgi.py" <<- 'EOS' > /dev/null
from myproject import app

if __name__ == "__main__":
    app.run()
EOS
```

## uWSGIのテスト
```sh
conda activate "$HOME/miniconda3/envs/myproject" &&
cd "$HOME/myproject" &&
uwsgi --socket 0.0.0.0:5000 --protocol=http -w wsgi:app
```
http://your_server_ip:5000

```sh
conda deactivate
```

## 【デバッグ用】仮想環境の削除
```sh
conda remove -n myproject --all
```

## 【デバッグ用】Minicondaのアンインストール
```sh
conda init --reverse --all
rm -rf "$HOME/miniconda3"
source "$HOME/.bashrc"
```

## nginxの構成
`/etc/nginx/sites-available/myproject.conf`で設定している`server_name`の`example.com`は仮の値であることに注意。
```sh
tee "$HOME/myproject/myproject.ini" <<- 'EOS' > /dev/null &&
[uwsgi]
module = wsgi:app

master = true
processes = 5

socket = myproject.sock
chmod-socket = 660
vacuum = true

die-on-term = true
EOS
sudo tee "/etc/systemd/system/myproject.service" <<- EOS > /dev/null &&
[Unit]
Description=uWSGI instance to serve myproject
After=network.target

[Service]
User=$USER
Group=www-data
WorkingDirectory=$HOME/myproject
Environment="PATH=$HOME/miniconda3/envs/myproject/bin"
ExecStart=$HOME/miniconda3/envs/myproject/bin/uwsgi --ini myproject.ini

[Install]
WantedBy=multi-user.target
EOS
chgrp www-data "$HOME" &&
chmod g+rx "$HOME" &&
sudo systemctl enable --now myproject &&
tee "/etc/nginx/sites-available/myproject.conf" <<- EOS > /dev/null &&
server {
  listen 80;
  server_name example.com;
  location / {
    include uwsgi_params;
    uwsgi_pass unix:$HOME/myproject/myproject.sock;
  }
}
EOS
sudo ln -s /etc/nginx/sites-available/myproject.conf /etc/nginx/sites-enabled/myproject.conf &&
sudo unlink /etc/nginx/sites-enabled/default &&
sudo systemctl restart nginx.service
```
