# Cloudflare Tunnel
[Create a locally-managed tunnel (CLI) · Cloudflare Zero Trust docs](https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/get-started/create-local-tunnel/)

```sh
tunnel_name="main" &&
container_user="cloudflared" &&
etc_dir="/usr/local/etc/cloudflared" &&
if ! id "${container_user}" &>/dev/null; then
    sudo useradd --system --create-home -u 65532 -g 65532 --user-group "${container_user}"
fi &&
sudo install -o root -g "${container_user}" -m 770 -d "${etc_dir}" &&
sudo podman run \
  --user "$(id -u "${container_user}"):$(id -g "${container_user}")" \
  docker.io/cloudflare/cloudflared:latest tunnel --no-autoupdate run --token eyJhIjoiZGVmZGU2YWNjMDExNTgzMTk0ZmRkOThiZjhhOGYyYTYiLCJ0IjoiZDg2ZmE2MjctZGRjMS00MDE0LWEyYWMtYWYwNTRiOTViMjc3IiwicyI6IlpXVXdZMll4TnpjdE56UXpNUzAwWXpVd0xXRmhaRFV0TnpWbU9HSXdPVEkxWkdFNSJ9


container_uid=65532 &&
container_gid=65532 &&
container_user="cloudflared" &&
etc_dir="/usr/local/etc/cloudflared" &&
sudo useradd --create-home --user-group "${container_user}" &&
sudo install -o "${container_uid}" -g "${container_gid}" -m 770 -d "${etc_dir}" &&
sudo podman run \
  --rm -it \
  --user "${container_uid}:${container_gid}" \
  -v "${etc_dir}:/home/nonroot/.cloudflared:Z" \
  docker.io/cloudflare/cloudflared:latest \
  login


sudo userdel "${container_user}" &&
sudo rm -drf "/home/${container_user}"
----

sudo ls -la /usr/local/etc/cloudflared
sudo podman run \
  --rm -it \
  --user "$(id -u "${container_user}"):$(id -g "${container_user}")" \
  -v "${etc_dir}:/home/nonroot/.cloudflared:Z" \
  --entrypoint "/bin/sh" \
  docker.io/cloudflare/cloudflared:latest

   
sudo podman run \
  --rm -it \
  --user "$(id -u "${container_user}"):$(id -g "${container_user}")" \
  -v "${etc_dir}:/home/nonroot/.cloudflared:Z" \
  docker.io/cloudflare/cloudflared:latest \
  tunnel create "${tunnel_name}"

/home/nonroot/.cloudflared
```

```sh
sudo userdel "${container_user}"
```